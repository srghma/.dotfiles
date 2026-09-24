#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "aristotlelib",
# ]
# ///

import argparse
import asyncio
from dataclasses import dataclass
from datetime import datetime
import inspect
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import textwrap
from typing import Any, Callable

try:
    import termios
    import tty
except ImportError:
    termios = None
    tty = None

from aristotlelib import AgentTask, Project, set_api_key

# Cache directory
CACHE_DIR = Path.home() / ".cache" / "aristotle"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

# Optional static project -> env var or key mapping
DEFAULT_PROJECT_TO_KEY_ENV: dict[str, str] = {}

# ANSI styles
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
MAGENTA = "\033[35m"
RED = "\033[31m"
BLUE = "\033[34m"
REVERSE = "\033[7m"

TERMINAL_STATUSES = {
    "COMPLETE",
    "COMPLETE_WITH_ERRORS",
    "FAILED",
    "CANCELLED",
    "ERROR",
}

ANSI_ESCAPE = re.compile(r"\x1b\[[0-9;]*[a-zA-Z]")


# ─────────────────────────────────────────────────────────────────────────────
# Domain Models & Auth
# ─────────────────────────────────────────────────────────────────────────────


@dataclass
class TaskInfo:
    task_id: str
    status: str
    raw_status: Any
    percent: int | None
    created_at: str
    prompt: str
    end_msg: str | None
    is_terminal: bool
    from_cache: bool = False
    task_obj: Any = None


@dataclass
class BranchTarget:
    branch: str
    project_id: str
    raw_target: str


def setup_auth(project_id: str | None = None) -> str:
    """
    Selects API key using:
    1. ARISTOTLE_PROJECT_ID_TO_KEY json env mapping (or DEFAULT_PROJECT_TO_KEY_ENV)
    2. Fallback to generic ARISTOTLE_API_KEY
    """
    mapping = dict(DEFAULT_PROJECT_TO_KEY_ENV)

    env_map_json = os.environ.get("ARISTOTLE_PROJECT_ID_TO_KEY")
    if env_map_json:
        try:
            custom_map = json.loads(env_map_json)
            if isinstance(custom_map, dict):
                mapping.update(custom_map)
        except Exception as e:
            print(
                f"{YELLOW}⚠️  Warning: Failed to parse ARISTOTLE_PROJECT_ID_TO_KEY: {e}{RESET}",
                file=sys.stderr,
            )

    api_key = None
    if project_id and project_id in mapping:
        val = str(mapping[project_id]).strip()
        if val.startswith("$"):
            var_name = val[1:]
            api_key = os.environ.get(var_name)
        elif val in os.environ:
            api_key = os.environ.get(val)
        else:
            api_key = val

    if not api_key:
        api_key = os.environ.get("ARISTOTLE_API_KEY")

    if not api_key:
        print(
            f"{RED}Error: Could not determine Aristotle API key for project '{project_id or 'unknown'}'.{RESET}\n"
            f"Please ensure ARISTOTLE_API_KEY or ARISTOTLE_PROJECT_ID_TO_KEY is set in your environment.",
            file=sys.stderr,
        )
        sys.exit(1)

    os.environ["ARISTOTLE_API_KEY"] = api_key
    set_api_key(api_key)
    return api_key


def parse_project_id(target: str) -> str:
    match = re.search(r"projects/([0-9a-fA-F-]{36})", target)
    if match:
        return match.group(1)
    match_uuid = re.search(
        r"([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})",
        target,
    )
    if match_uuid:
        return match_uuid.group(1)
    return target


def extract_status_str(status_raw: Any) -> str:
    return str(getattr(status_raw, "value", status_raw)).split(".")[-1]


def status_badge(status_raw: Any, percent: int | None = None) -> str:
    s = extract_status_str(status_raw)
    pct = f" ({percent}%)" if percent is not None and "PROGRESS" in s else ""
    if "PROGRESS" in s:
        return f"{YELLOW}🔄 {s}{pct}{RESET}"
    if "ERROR" in s:
        return f"{RED}⚠️  {s}{RESET}"
    if "COMPLETE" in s or "SUCCESS" in s:
        return f"{GREEN}✅ {s}{RESET}"
    if "FAIL" in s:
        return f"{RED}❌ {s}{RESET}"
    if "QUEUE" in s:
        return f"{BLUE}⏳ {s}{RESET}"
    return f"ℹ️  {s}{pct}"


def format_badge_fixed_width(status_raw: Any, percent: int | None = None) -> str:
    s = extract_status_str(status_raw)
    pct = f" {percent}%" if percent is not None and "PROGRESS" in s else ""
    if "PROGRESS" in s:
        lbl = f"🔄 IN_PROG{pct}"
        return f"{YELLOW}{lbl:<15}{RESET}"
    if "ERROR" in s:
        return f"{RED}⚠️  ERROR      {RESET}"
    if "COMPLETE" in s or "SUCCESS" in s:
        return f"{GREEN}✅ COMPLETE   {RESET}"
    if "FAIL" in s:
        return f"{RED}❌ FAILED     {RESET}"
    if "CANCEL" in s:
        return f"{RED}🚫 CANCELLED  {RESET}"
    if "QUEUE" in s:
        return f"{BLUE}⏳ QUEUED     {RESET}"
    return f"{DIM}ℹ️  {s[:11]:<11}{RESET}"


def extract_task_id(task: Any) -> str | None:
    if isinstance(task, dict):
        return (
            task.get("agent_task_id")
            or task.get("id")
            or task.get("object_id")
        )
    for attr in ("agent_task_id", "id", "object_id"):
        val = getattr(task, attr, None)
        if val:
            return str(val)
    if hasattr(task, "model_dump"):
        d = task.model_dump()
        return d.get("agent_task_id") or d.get("id") or d.get("object_id")
    return None


async def fetch_project_tasks(project: Project, limit: int = 10):
    res = project.get_tasks(limit=limit)
    if inspect.isawaitable(res):
        res = await res
    if isinstance(res, tuple):
        return res[0]
    if hasattr(res, "tasks"):
        return res.tasks
    if isinstance(res, list):
        return res
    return [res]


# ─────────────────────────────────────────────────────────────────────────────
# Text Formatting & Git Helpers
# ─────────────────────────────────────────────────────────────────────────────


def visible_len(s: str) -> int:
    return len(ANSI_ESCAPE.sub("", s))


def truncate_visible(s: str, max_width: int) -> str:
    cur_width = 0
    res = []
    tokens = re.split(r"(\x1b\[[0-9;]*[a-zA-Z])", s)
    for tok in tokens:
        if not tok:
            continue
        if tok.startswith("\x1b["):
            res.append(tok)
        else:
            for ch in tok:
                if cur_width >= max_width:
                    res.append("…")
                    res.append(RESET)
                    return "".join(res)
                res.append(ch)
                cur_width += 1
    return "".join(res)


def pad_visible(s: str, width: int) -> str:
    vlen = visible_len(s)
    if vlen < width:
        return s + " " * (width - vlen)
    return truncate_visible(s, width)


def extract_first_line_prompt(prompt: str | None, max_chars: int = 60) -> str:
    if not prompt:
        return ""
    for raw_line in prompt.strip().splitlines():
        line = raw_line.strip()
        line = re.sub(r"^#+\s*", "", line)
        line = re.sub(r"^[-*]\s*", "", line)
        if line:
            if len(line) > max_chars:
                line = line[: max_chars - 3].rsplit(" ", 1)[0] + "..."
            return line
    return ""


def build_git_commit_message(
    task: TaskInfo | None = None,
    *,
    task_id: str | None = None,
    status_str: str | None = None,
    prompt: str | None = None,
    end_msg: str | None = None,
) -> str:
    if task is not None:
        t_id = task.task_id
        st = task.status
        pr = task.prompt
        end = task.end_msg
    else:
        t_id = task_id or ""
        st = status_str or ""
        pr = prompt or ""
        end = end_msg

    first_line = extract_first_line_prompt(pr, max_chars=60)
    commit_title = f"Aristotle: {t_id[:8]} ({st})"
    if first_line:
        commit_title += f" - {first_line}"

    lines = [
        commit_title,
        "",
        f"Task ID: {t_id}",
        f"Status:  {st}",
        "",
        "=== My Prompt ===",
        pr.strip() if pr else "(No prompt recorded)",
    ]

    if st in TERMINAL_STATUSES:
        lines.append("")
        lines.append("=== Aristotle End Message ===")
        lines.append(end.strip() if end else "(No end message)")

    return "\n".join(lines)


def is_task_in_git(task_id: str, branch: str | None = None) -> bool:
    try:
        cmd = ["git", "log"]
        if branch:
            cmd.append(branch)
        cmd.extend(["-n", "50", f"--grep=Task ID: {task_id}"])
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            return True

        cmd[-1] = f"--grep=Aristotle: {task_id[:8]}"
        res = subprocess.run(cmd, capture_output=True, text=True)
        return res.returncode == 0 and bool(res.stdout.strip())
    except Exception:
        return False


def git_checkout(branch: str) -> bool:
    git_status = subprocess.run(
        ["git", "status", "--porcelain"], capture_output=True, text=True
    ).stdout.strip()

    if git_status:
        print(
            f"{RED}⚠️  Cannot switch to branch '{branch}': working tree has uncommitted changes.{RESET}\n"
            f"{DIM}{git_status}{RESET}",
            file=sys.stderr,
        )
        return False

    current_branch = subprocess.run(
        ["git", "branch", "--show-current"], capture_output=True, text=True
    ).stdout.strip()
    if current_branch == branch:
        return True

    res = subprocess.run(["git", "checkout", branch], capture_output=True, text=True)
    if res.returncode != 0:
        print(
            f"{RED}⚠️  Failed to checkout '{branch}':\n{res.stderr}{RESET}",
            file=sys.stderr,
        )
        return False
    return True


def git_commit_changes(commit_msg: str, push: bool = True) -> bool:
    git_status = subprocess.run(
        ["git", "status", "--porcelain"], capture_output=True, text=True
    ).stdout.strip()

    if not git_status:
        print(f"{DIM}No git working tree changes detected.{RESET}")
        return False

    print(f"{BOLD}{GREEN}📝 Changes detected. Committing...{RESET}")
    subprocess.run(["git", "add", "."], check=True)
    subprocess.run(["git", "commit", "-m", commit_msg], check=True)

    if push:
        print(f"{BOLD}{BLUE}🚀 Pushing to remote...{RESET}")
        try:
            subprocess.run(["git", "push"], check=True)
        except subprocess.CalledProcessError as e:
            print(f"{RED}⚠️  Git push failed: {e}{RESET}")
            return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Task Caching & Extraction Helpers
# ─────────────────────────────────────────────────────────────────────────────


def load_task_cache(task_id: str):
    f = CACHE_DIR / f"{task_id}.json"
    if f.exists():
        try:
            with open(f, "r", encoding="utf-8") as fp:
                return json.load(fp)
        except Exception:
            return None
    return None


def save_task_cache(task_id: str, data: dict):
    f = CACHE_DIR / f"{task_id}.json"
    try:
        with open(f, "w", encoding="utf-8") as fp:
            json.dump(data, fp, indent=2, ensure_ascii=False)
    except Exception:
        pass


def get_synced_tasks(project_id: str) -> set:
    f = CACHE_DIR / f"synced_{project_id}.json"
    if f.exists():
        try:
            with open(f, "r", encoding="utf-8") as fp:
                return set(json.load(fp).get("synced_task_ids", []))
        except Exception:
            return set()
    return set()


def mark_task_synced(project_id: str, task_id: str):
    synced = get_synced_tasks(project_id)
    synced.add(task_id)
    f = CACHE_DIR / f"synced_{project_id}.json"
    try:
        with open(f, "w", encoding="utf-8") as fp:
            json.dump({"synced_task_ids": sorted(list(synced))}, fp, indent=2)
    except Exception:
        pass


async def extract_initial_prompt(task: Any) -> str:
    try:
        res = task.get_events(limit=100)
        if inspect.isawaitable(res):
            res = await res
        events = res[0] if isinstance(res, tuple) else res
        for ev in reversed(events):
            d = ev.model_dump() if hasattr(ev, "model_dump") else vars(ev)
            if d.get("event_type") == 1 or d.get("type") == 1:
                content = d.get("content") or d.get("message")
                if content and content.strip():
                    return content.strip()
    except Exception:
        pass
    return (
        getattr(task, "description", None)
        or getattr(task, "name", None)
        or "No prompt found"
    )


async def get_task_details(task_obj: Any, task_id: str, status_str: str):
    cached = load_task_cache(task_id)
    if (
        cached
        and cached.get("status") in TERMINAL_STATUSES
        and cached.get("prompt")
    ):
        return cached["prompt"], cached.get("output_summary"), True

    end_msg = getattr(task_obj, "output_summary", None)
    if hasattr(task_obj, "model_dump"):
        end_msg = end_msg or task_obj.model_dump().get("output_summary")

    full_task = task_obj
    if not hasattr(full_task, "get_events"):
        full_task = await AgentTask.from_id(task_id)
        if not end_msg:
            end_msg = getattr(full_task, "output_summary", None)

    prompt = await extract_initial_prompt(full_task)

    if status_str in TERMINAL_STATUSES:
        save_task_cache(
            task_id,
            {
                "task_id": task_id,
                "status": status_str,
                "prompt": prompt,
                "output_summary": end_msg,
            },
        )
    return prompt, end_msg, False


async def get_task_info(task_obj: Any, task_id: str | None = None) -> TaskInfo | None:
    t_id = task_id or extract_task_id(task_obj)
    if not t_id:
        return None
    raw_status = getattr(task_obj, "status", "")
    status_str = extract_status_str(raw_status)
    pct = getattr(task_obj, "percent_complete", None)
    created_at = str(getattr(task_obj, "created_at", "N/A"))

    prompt, end_msg, from_cache = await get_task_details(
        task_obj, t_id, status_str
    )

    return TaskInfo(
        task_id=t_id,
        status=status_str,
        raw_status=raw_status,
        percent=pct,
        created_at=created_at,
        prompt=prompt,
        end_msg=end_msg,
        is_terminal=(status_str in TERMINAL_STATUSES),
        from_cache=from_cache,
        task_obj=task_obj,
    )


async def fetch_tasks_info(
    raw_tasks: list,
    max_concurrency: int = 5,
    on_progress: Callable[[int, int], None] | None = None,
) -> list[TaskInfo]:
    sem = asyncio.Semaphore(max_concurrency)
    total = len(raw_tasks)
    completed = 0

    async def _load(t):
        nonlocal completed
        async with sem:
            info = await get_task_info(t)
        completed += 1
        if on_progress:
            on_progress(completed, total)
        return info

    results = await asyncio.gather(*(_load(t) for t in raw_tasks))
    return [r for r in results if r is not None]


# ─────────────────────────────────────────────────────────────────────────────
# Full-Screen Interactive Task Selector
# ─────────────────────────────────────────────────────────────────────────────


def read_terminal_key(fd: int) -> str:
    b = os.read(fd, 32)
    if not b:
        return ""
    if b in (b"\x1b[A", b"\x1bOA"):
        return "UP"
    if b in (b"\x1b[B", b"\x1bOB"):
        return "DOWN"
    if b in (b"\x1b[C", b"\x1bOC"):
        return "RIGHT"
    if b in (b"\x1b[D", b"\x1bOD"):
        return "LEFT"
    if b == b"\x1b[5~":
        return "PAGE_UP"
    if b == b"\x1b[6~":
        return "PAGE_DOWN"
    if b in (b"\x1b[H", b"\x1b[1~"):
        return "HOME"
    if b in (b"\x1b[F", b"\x1b[4~"):
        return "END"
    if b in (b"\r", b"\n"):
        return "ENTER"
    if b == b" ":
        return "SPACE"
    if b == b"\x1b":
        return "ESC"
    if b == b"\x03":
        return "CTRL_C"
    if b == b"\x04":
        return "CTRL_D"
    try:
        return b.decode("utf-8", errors="ignore")
    except Exception:
        return ""


def select_task_interactive(tasks_info: list[TaskInfo], project_id: str) -> TaskInfo | None:
    if not termios or not tty:
        return tasks_info[0] if tasks_info else None

    try:
        tty_in = open("/dev/tty", "rb", buffering=0)
        tty_out = open("/dev/tty", "w", encoding="utf-8")
    except Exception:
        return tasks_info[0] if tasks_info else None

    fd_in = tty_in.fileno()
    old_settings = termios.tcgetattr(fd_in)

    selected_idx = 0
    scroll_top = 0

    def sigwinch_handler(signum, frame):
        pass

    if hasattr(signal, "SIGWINCH"):
        try:
            signal.signal(signal.SIGWINCH, sigwinch_handler)
        except Exception:
            pass

    try:
        tty.setcbreak(fd_in)
        tty_out.write("\033[?1049h\033[?25l")
        tty_out.flush()

        while True:
            cols, rows = shutil.get_terminal_size(fallback=(100, 30))
            cols = max(cols, 60)
            rows = max(rows, 16)

            list_height = max(3, min(len(tasks_info), (rows - 9) // 2))

            if selected_idx < scroll_top:
                scroll_top = selected_idx
            elif selected_idx >= scroll_top + list_height:
                scroll_top = selected_idx - list_height + 1

            screen_lines = []

            # Header
            header_title = f" 🧠 ARISTOTLE TASK SELECTOR  {DIM}•  Project: {project_id}{RESET}"
            screen_lines.append(f"┌─{pad_visible(header_title, cols - 3)}┐")
            screen_lines.append(
                f"│ {BOLD}Select a task to generate its git commit message:{RESET}"
                + " " * max(0, cols - 51)
                + "│"
            )
            screen_lines.append("├" + "─" * (cols - 2) + "┤")

            # Task list
            for i in range(list_height):
                item_idx = scroll_top + i
                if item_idx < len(tasks_info):
                    item = tasks_info[item_idx]
                    is_sel = item_idx == selected_idx
                    tag = f"[{item_idx + 1}]"
                    badge = format_badge_fixed_width(
                        item.raw_status, item.percent
                    )
                    created_raw = item.created_at
                    created = (
                        created_raw[5:16]
                        if len(created_raw) >= 16
                        else created_raw
                    )
                    p_summary = extract_first_line_prompt(
                        item.prompt, max_chars=max(15, cols - 52)
                    )

                    if is_sel:
                        row_txt = f"{BOLD}{CYAN}❯ {tag:<4}{RESET} {badge} {BOLD}{item.task_id[:8]}{RESET} {DIM}{created}{RESET}  {BOLD}{p_summary}{RESET}"
                    else:
                        row_txt = f"  {DIM}{tag:<4}{RESET} {badge} {item.task_id[:8]} {DIM}{created}{RESET}  {p_summary}"

                    screen_lines.append(f"│ {pad_visible(row_txt, cols - 4)} │")
                else:
                    screen_lines.append(f"│{' ' * (cols - 2)}│")

            # Middle Divider
            cur_item = tasks_info[selected_idx]
            mid_title = f" Details Preview: {cur_item.task_id[:8]} ({cur_item.status}) "
            screen_lines.append(
                f"├─{BOLD}{CYAN}{mid_title}{RESET}"
                + "─" * max(0, cols - visible_len(mid_title) - 3)
                + "┤"
            )

            # Preview Pane
            preview_max_lines = rows - len(screen_lines) - 2
            preview_body = []

            preview_body.append(
                f"  {BOLD}Task ID:{RESET}  {CYAN}{cur_item.task_id}{RESET}"
            )
            preview_body.append(
                f"  {BOLD}Status:{RESET}   {status_badge(cur_item.raw_status, cur_item.percent)}"
            )
            preview_body.append(
                f"  {BOLD}Created:{RESET}  {DIM}{cur_item.created_at}{RESET}"
            )
            preview_body.append("")
            preview_body.append(f"  {BOLD}{CYAN}📥 My Prompt:{RESET}")

            p_text = (
                cur_item.prompt.strip()
                if cur_item.prompt
                else "(No prompt recorded)"
            )
            for pl in p_text.splitlines():
                if not pl.strip():
                    preview_body.append("")
                else:
                    wrapped = textwrap.wrap(pl, width=max(20, cols - 8)) or [""]
                    for w in wrapped:
                        preview_body.append(f"    {w}")

            if cur_item.is_terminal:
                preview_body.append("")
                preview_body.append(
                    f"  {BOLD}{GREEN}📤 Aristotle Response Summary:{RESET}"
                )
                end_text = (
                    cur_item.end_msg.strip()
                    if cur_item.end_msg
                    else "(No end message recorded)"
                )
                for el in end_text.splitlines():
                    if not el.strip():
                        preview_body.append("")
                    else:
                        wrapped = textwrap.wrap(
                            el, width=max(20, cols - 8)
                        ) or [""]
                        for w in wrapped:
                            preview_body.append(f"    {w}")
            else:
                preview_body.append("")
                preview_body.append(
                    f"  {YELLOW}⏳ Task is in progress — Git commit message will contain prompt only.{RESET}"
                )

            for pi in range(preview_max_lines):
                if pi < len(preview_body):
                    if (
                        pi == preview_max_lines - 1
                        and len(preview_body) > preview_max_lines
                    ):
                        line_str = f"  {DIM}... ({len(preview_body) - preview_max_lines + 1} more lines) ...{RESET}"
                    else:
                        line_str = preview_body[pi]
                    screen_lines.append(f"│{pad_visible(line_str, cols - 2)}│")
                else:
                    screen_lines.append(f"│{' ' * (cols - 2)}│")

            # Help Bar
            help_str = " [↑/k] Up  [↓/j] Down  [1-9] Jump  [Enter] Select & Commit  [q/Esc] Cancel "
            screen_lines.append(
                f"└─{DIM}{help_str}{RESET}"
                + "─" * max(0, cols - visible_len(help_str) - 3)
                + "┘"
            )

            # Draw
            draw_buf = ["\033[H"]
            for sl in screen_lines[:rows]:
                draw_buf.append(pad_visible(sl, cols))
            draw_buf.append("\033[J")
            tty_out.write("\n".join(draw_buf))
            tty_out.flush()

            key = read_terminal_key(fd_in)
            if key in ("UP", "k", "K"):
                selected_idx = max(0, selected_idx - 1)
            elif key in ("DOWN", "j", "J"):
                selected_idx = min(len(tasks_info) - 1, selected_idx + 1)
            elif key == "PAGE_UP":
                selected_idx = max(0, selected_idx - list_height)
            elif key == "PAGE_DOWN":
                selected_idx = min(
                    len(tasks_info) - 1, selected_idx + list_height
                )
            elif key in ("HOME", "g"):
                selected_idx = 0
            elif key in ("END", "G"):
                selected_idx = len(tasks_info) - 1
            elif key in ("ENTER", "SPACE"):
                return tasks_info[selected_idx]
            elif key in ("ESC", "q", "Q", "CTRL_C", "CTRL_D"):
                return None
            elif key.isdigit() and 1 <= int(key) <= len(tasks_info):
                selected_idx = int(key) - 1

    finally:
        tty_out.write("\033[?1049l\033[?25h")
        tty_out.flush()
        termios.tcsetattr(fd_in, termios.TCSADRAIN, old_settings)
        tty_in.close()
        tty_out.close()


# ─────────────────────────────────────────────────────────────────────────────
# Command 1: last_3_tasks_my_prompts_and_its_end_message
# ─────────────────────────────────────────────────────────────────────────────


async def cmd_last_3_tasks(project_id: str):
    project = await Project.from_id(project_id)
    raw_tasks = await fetch_project_tasks(project, limit=3)
    tasks_info = await fetch_tasks_info(raw_tasks)

    print(
        f"\n{BOLD}{MAGENTA}🚀 Aristotle Project:{RESET} {CYAN}{project_id}{RESET}"
    )
    print(f"{DIM}Cache: {CACHE_DIR}{RESET}\n")

    labels = ["Latest", "Previous 1", "Previous 2"]
    for i, t in enumerate(tasks_info):
        tag = labels[i] if i < len(labels) else f"Previous {i}"
        cache_badge = (
            f"{DIM}[💾 cached]{RESET}" if t.from_cache else f"{CYAN}[🌐 live]{RESET}"
        )

        print(f"{BOLD}{MAGENTA}┌─ [{tag}] {t.task_id} {cache_badge}{RESET}")
        print(f"{MAGENTA}│{RESET}  Status:      {status_badge(t.raw_status, t.percent)}")
        print(f"{MAGENTA}│{RESET}  Created:     {DIM}{t.created_at}{RESET}")
        print(f"{MAGENTA}│{RESET}")
        print(f"{MAGENTA}│{RESET}  {BOLD}{CYAN}📥 My Prompt:{RESET}")
        for line in t.prompt.strip().splitlines():
            print(f"{MAGENTA}│{RESET}     {line}")

        if t.end_msg:
            print(f"{MAGENTA}│{RESET}")
            print(f"{MAGENTA}│{RESET}  {BOLD}{GREEN}📤 Aristotle Response:{RESET}")
            for line in t.end_msg.strip().splitlines():
                print(f"{MAGENTA}│{RESET}     {line}")

        print(
            f"{BOLD}{MAGENTA}└──────────────────────────────────────────────────────────{RESET}\n"
        )


# ─────────────────────────────────────────────────────────────────────────────
# Command 2: pull_force & File Cleanup Helpers
# ─────────────────────────────────────────────────────────────────────────────


def is_empty_file(path: Path) -> bool:
    try:
        if not path.is_file() or path.is_symlink():
            return False
        stat = path.stat()
        if stat.st_size == 0:
            return True
        if stat.st_size <= 4096:
            with open(path, "rb") as f:
                return f.read().strip() == b""
    except OSError:
        pass
    return False


def remove_empty_files_in_folder(folder: Path, cwd: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    removed = []
    for item in sorted(folder.rglob("*")):
        if ".git" in item.parts or item.name in {".gitkeep", ".keep", ".gitignore"}:
            continue
        if is_empty_file(item):
            try:
                item.unlink()
                rel = item.relative_to(cwd) if item.is_relative_to(cwd) else item
                print(f"{YELLOW}🗑️  Removed empty file: {rel}{RESET}")
                removed.append(item)
            except OSError as e:
                print(f"{RED}⚠️  Failed to remove empty file {item}: {e}{RESET}")
    return removed


def execute_pull(project_id: str, paths: list[str]) -> bool:
    print(
        f"{BOLD}{BLUE}==> Downloading Aristotle project:{RESET} {CYAN}{project_id}{RESET} ..."
    )

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        archive_path = tmp_path / "archive.tar.gz"
        extracted_path = tmp_path / "extracted"
        extracted_path.mkdir(parents=True, exist_ok=True)

        cmd = [
            "aristotle",
            "download",
            project_id,
            "--destination",
            str(archive_path),
        ]
        if not shutil.which("aristotle"):
            cmd = [
                "uv",
                "run",
                "--with",
                "aristotlelib",
                "aristotle",
                "download",
                project_id,
                "--destination",
                str(archive_path),
            ]

        res = subprocess.run(cmd, capture_output=True, text=True, env=os.environ)
        if res.returncode != 0:
            print(
                f"{RED}Download failed:{RESET}\n{res.stderr or res.stdout}",
                file=sys.stderr,
            )
            return False

        print(
            f"{BOLD}{BLUE}==> Extracting files to sync ({', '.join(paths)}) ...{RESET}"
        )
        extract_res = subprocess.run(
            [
                "tar",
                "-xzf",
                str(archive_path),
                "-C",
                str(extracted_path),
            ],
            capture_output=True,
            text=True,
        )
        if extract_res.returncode != 0:
            print(
                f"{RED}Extraction failed:{RESET}\n{extract_res.stderr}",
                file=sys.stderr,
            )
            return False

        root_path = extracted_path
        first_clean = paths[0].strip("/")
        if not (extracted_path / first_clean).exists():
            subdirs = [
                d
                for d in extracted_path.iterdir()
                if d.is_dir() and not d.name.startswith(".")
            ]
            for s in subdirs:
                if (s / first_clean).exists():
                    root_path = s
                    break
            else:
                if len(subdirs) == 1:
                    root_path = subdirs[0]

        cwd = Path.cwd()
        synced_dirs = set()
        for p_str in paths:
            clean_p = p_str.strip("/")
            src = root_path / clean_p
            dst = cwd / clean_p

            if not src.exists():
                print(
                    f"{YELLOW}⚠️  Warning: {clean_p} not found in extracted archive.{RESET}"
                )
                continue

            if src.is_dir():
                dst.mkdir(parents=True, exist_ok=True)
                rsync_cmd = ["rsync", "-av", "--delete", f"{src}/", f"{dst}/"]
                synced_dirs.add(dst.resolve())
            else:
                dst.parent.mkdir(parents=True, exist_ok=True)
                rsync_cmd = ["rsync", "-av", str(src), str(dst)]

            subprocess.run(rsync_cmd, check=True)

        for folder in sorted(synced_dirs):
            remove_empty_files_in_folder(folder, cwd)

    print(f"{GREEN}==> Sync complete!{RESET}\n")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Command 3: watch_and_pull
# ─────────────────────────────────────────────────────────────────────────────


async def cmd_watch_and_pull(
    project_id: str, paths: list[str], interval: int, no_push: bool
):
    print(
        f"\n{BOLD}{MAGENTA}👀 Watching Aristotle Project:{RESET} {CYAN}{project_id}{RESET}"
    )
    print(f"{BOLD}Configured sync paths:{RESET} {YELLOW}{', '.join(paths)}{RESET}")
    print(f"{BOLD}Poll interval:{RESET} {interval}s\n")

    synced_task_ids = get_synced_tasks(project_id)

    while True:
        try:
            project = await Project.from_id(project_id)
            tasks = await fetch_project_tasks(project, limit=10)

            if not tasks:
                now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                print(
                    f"[{DIM}{now_str}{RESET}] ⚠️  No tasks found for project. Waiting {interval}s..."
                )
                await asyncio.sleep(interval)
                continue

            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # 1. Find the newest terminal task
            latest_terminal_task = None
            for t in tasks:
                st = extract_status_str(getattr(t, "status", ""))
                if st in TERMINAL_STATUSES:
                    latest_terminal_task = t
                    break

            synced_something = False
            if latest_terminal_task:
                term_id = extract_task_id(latest_terminal_task)
                is_synced = (term_id in synced_task_ids) or is_task_in_git(term_id)

                if not is_synced:
                    raw_status = getattr(latest_terminal_task, "status", "")
                    pct = getattr(latest_terminal_task, "percent_complete", None)
                    badge = status_badge(raw_status, pct)
                    print(
                        f"\n[{BOLD}{now_str}{RESET}] 🎉 Task {BOLD}{CYAN}{term_id}{RESET} finished with: {badge}"
                    )

                    task_info = await get_task_info(latest_terminal_task, term_id)
                    if task_info:
                        success = execute_pull(project_id, paths)
                        if not success:
                            print(
                                f"{RED}Pull failed. Will retry in {interval}s...{RESET}",
                                file=sys.stderr,
                            )
                            await asyncio.sleep(interval)
                            continue

                        commit_msg = build_git_commit_message(task_info)
                        git_commit_changes(commit_msg, push=(not no_push))

                        # Mark this and older tasks as synced
                        for t in tasks:
                            tid = extract_task_id(t)
                            if tid:
                                mark_task_synced(project_id, tid)
                                synced_task_ids.add(tid)

                        print(
                            f"{GREEN}✔ Task {term_id} successfully processed.{RESET} Resuming watch in {interval}s...\n"
                        )
                        synced_something = True

            # 2. If nothing was synced, report status
            if not synced_something:
                latest_task = tasks[0]
                latest_task_id = extract_task_id(latest_task)
                raw_status = getattr(latest_task, "status", "")
                status_str = extract_status_str(raw_status)
                pct = getattr(latest_task, "percent_complete", None)
                badge = status_badge(raw_status, pct)

                if status_str not in TERMINAL_STATUSES:
                    print(
                        f"[{DIM}{now_str}{RESET}] ⏳ Task {CYAN}{latest_task_id[:8] if latest_task_id else 'unknown'}{RESET}... {badge}. Waiting {interval}s..."
                    )
                else:
                    print(
                        f"[{DIM}{now_str}{RESET}] 💤 Latest task {CYAN}{latest_task_id[:8] if latest_task_id else 'unknown'}{RESET}... is {badge} (already synced). Waiting {interval}s..."
                    )

            await asyncio.sleep(interval)

        except KeyboardInterrupt:
            print(f"\n{YELLOW}Watcher stopped by user.{RESET}")
            break
        except Exception as e:
            print(f"{RED}Unexpected error in watch loop: {e}{RESET}")
            await asyncio.sleep(interval)


# ─────────────────────────────────────────────────────────────────────────────
# Command 4: task_to_git_message
# ─────────────────────────────────────────────────────────────────────────────


async def cmd_task_to_git_message(
    project_id: str,
    limit: int = 15,
    task_id: str | None = None,
    latest: bool = False,
    commit: bool = False,
    no_push: bool = False,
):
    if task_id:
        task_obj = await AgentTask.from_id(task_id)
        chosen = await get_task_info(task_obj, task_id)
        if not chosen:
            print(
                f"{RED}Error: Could not retrieve task {task_id}{RESET}",
                file=sys.stderr,
            )
            sys.exit(1)

        commit_msg = build_git_commit_message(chosen)
        if commit:
            git_commit_changes(commit_msg, push=(not no_push))
        else:
            print(commit_msg)
        return

    try:
        tty_status = open("/dev/tty", "w")
    except Exception:
        tty_status = sys.stderr

    tty_status.write(
        f"{CYAN}⏳ Fetching recent Aristotle tasks for project {project_id[:8]}...{RESET}\n"
    )
    tty_status.flush()

    project = await Project.from_id(project_id)
    raw_tasks = await fetch_project_tasks(project, limit=limit)

    if not raw_tasks:
        print(
            f"{RED}No tasks found for project {project_id}.{RESET}",
            file=sys.stderr,
        )
        sys.exit(1)

    tasks_info = await fetch_tasks_info(
        raw_tasks,
        on_progress=lambda done, total: (
            tty_status.write(
                f"\r{CYAN}⏳ Loading task details ({done}/{total})...{RESET}"
            ),
            tty_status.flush(),
        ),
    )

    if not tasks_info:
        print(f"{RED}No valid tasks found.{RESET}", file=sys.stderr)
        sys.exit(1)

    if latest:
        chosen = tasks_info[0]
    else:
        chosen = select_task_interactive(tasks_info, project_id)

    if not chosen:
        print(
            f"{YELLOW}Commit message generation cancelled.{RESET}",
            file=sys.stderr,
        )
        sys.exit(1)

    commit_msg = build_git_commit_message(chosen)

    if commit:
        git_commit_changes(commit_msg, push=(not no_push))
    else:
        print(commit_msg)


# ─────────────────────────────────────────────────────────────────────────────
# Command 5: watch_branches (Multi-branch / Multi-project watcher)
# ─────────────────────────────────────────────────────────────────────────────


async def cmd_watch_branches(
    targets: list[BranchTarget],
    paths: list[str],
    interval: int = 60,
    no_push: bool = False,
):
    print(f"\n{BOLD}{MAGENTA}👀 Multi-Branch Aristotle Watcher Started{RESET}")
    print(f"{BOLD}Configured targets:{RESET}")
    for t in targets:
        print(f"  • {BOLD}{CYAN}{t.branch:<10}{RESET} -> {YELLOW}{t.project_id}{RESET}")
    print(f"{BOLD}Sync paths:{RESET} {YELLOW}{', '.join(paths)}{RESET}")
    print(f"{BOLD}Poll interval:{RESET} {interval}s\n")

    while True:
        try:
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            for t in targets:
                setup_auth(t.project_id)
                synced_task_ids = get_synced_tasks(t.project_id)

                try:
                    project = await Project.from_id(t.project_id)
                    tasks = await fetch_project_tasks(project, limit=10)
                except Exception as e:
                    print(
                        f"[{DIM}{now_str}{RESET}] [{CYAN}{t.branch}{RESET}] ⚠️  Error fetching tasks: {e}"
                    )
                    continue

                if not tasks:
                    continue

                # 1. Find the newest terminal task
                latest_terminal_task = None
                for task_item in tasks:
                    st = extract_status_str(getattr(task_item, "status", ""))
                    if st in TERMINAL_STATUSES:
                        latest_terminal_task = task_item
                        break

                synced_something = False
                if latest_terminal_task:
                    term_id = extract_task_id(latest_terminal_task)
                    is_synced = (term_id in synced_task_ids) or is_task_in_git(term_id, t.branch)

                    if not is_synced:
                        raw_status = getattr(latest_terminal_task, "status", "")
                        pct = getattr(latest_terminal_task, "percent_complete", None)
                        badge = status_badge(raw_status, pct)
                        print(
                            f"\n[{BOLD}{now_str}{RESET}] 🎉 [{BOLD}{CYAN}{t.branch}{RESET}] "
                            f"New finished task {BOLD}{CYAN}{term_id}{RESET}: {badge}"
                        )

                        task_info = await get_task_info(latest_terminal_task, term_id)
                        if not task_info:
                            continue

                        # Switch git branch
                        print(f"{BOLD}Checking out {CYAN}{t.branch}{RESET}...{RESET}")
                        if not git_checkout(t.branch):
                            print(
                                f"{RED}Skipping sync for {t.branch} due to uncommitted working tree changes.{RESET}"
                            )
                            continue

                        # Pull & sync files
                        success = execute_pull(t.project_id, paths)
                        if not success:
                            print(
                                f"{RED}Pull failed for {t.branch}. Will retry next cycle.{RESET}",
                                file=sys.stderr,
                            )
                            continue

                        # Commit with prompt + response message
                        commit_msg = build_git_commit_message(task_info)
                        git_commit_changes(commit_msg, push=(not no_push))

                        # Mark this and older tasks as synced
                        for task_item in tasks:
                            tid = extract_task_id(task_item)
                            if tid:
                                mark_task_synced(t.project_id, tid)
                                synced_task_ids.add(tid)

                        print(
                            f"{GREEN}✔ Successfully updated branch '{t.branch}' with task {term_id[:8]}.{RESET}\n"
                        )
                        synced_something = True

                # 2. If nothing was synced, report status if latest task is still active
                if not synced_something:
                    latest_task = tasks[0]
                    latest_task_id = extract_task_id(latest_task)
                    raw_status = getattr(latest_task, "status", "")
                    status_str = extract_status_str(raw_status)
                    pct = getattr(latest_task, "percent_complete", None)

                    if status_str not in TERMINAL_STATUSES:
                        badge = status_badge(raw_status, pct)
                        print(
                            f"[{DIM}{now_str}{RESET}] [{CYAN}{t.branch:<6}{RESET}] ⏳ Task {CYAN}{latest_task_id[:8] if latest_task_id else 'unknown'}{RESET}... {badge}"
                        )

        except KeyboardInterrupt:
            print(f"\n{YELLOW}Watcher stopped by user.{RESET}")
            break
        except Exception as e:
            print(f"{RED}Unexpected error in watch loop: {e}{RESET}")

        await asyncio.sleep(interval)


# ─────────────────────────────────────────────────────────────────────────────
# CLI Entrypoint
# ─────────────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="myaristotle - Aristotle task viewer, force puller, and watcher"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # 1. last_3_tasks
    p_last = subparsers.add_parser(
        "last_3_tasks_my_prompts_and_its_end_message",
        aliases=["last3", "status"],
        help="Show status of last 3 tasks, user prompts, and Aristotle responses",
    )
    p_last.add_argument(
        "project",
        nargs="?",
        default="6ad53d96-a66b-4f9b-9787-563ecc92c6fa",
        help="Project ID or URL (default: 6ad53d96-a66b-4f9b-9787-563ecc92c6fa)",
    )

    # 2. pull_force
    p_pull = subparsers.add_parser(
        "pull_force", help="Force pull and sync configured directories/files"
    )
    p_pull.add_argument("project", help="Project ID or URL")
    p_pull.add_argument(
        "paths",
        nargs="+",
        help="Paths to sync (e.g. LeanScript/ TyTests/ NonEmpty/ lakefile.toml)",
    )

    # 3. watch_and_pull
    p_watch = subparsers.add_parser(
        "watch_and_pull",
        help="Watch task, pull when finished, commit prompt & response, and push",
    )
    p_watch.add_argument("project", help="Project ID or URL")
    p_watch.add_argument(
        "paths",
        nargs="*",
        help="Paths to sync (positional or via --paths)",
    )
    p_watch.add_argument(
        "--paths",
        nargs="+",
        dest="opt_paths",
        help="Paths to sync (e.g. --paths LeanScript/ TyTests/ lakefile.toml)",
    )
    p_watch.add_argument(
        "--interval",
        "-i",
        type=int,
        default=60,
        help="Poll interval in seconds (default: 60)",
    )
    p_watch.add_argument(
        "--no-push",
        action="store_true",
        help="Do not git push after commit",
    )

    # 4. task_to_git_message
    p_msg = subparsers.add_parser(
        "task_to_git_message",
        aliases=["completed_task_to_git_message", "commit_msg", "msg"],
        help="Interactive full-screen task selector to generate a git commit message",
    )
    p_msg.add_argument(
        "project",
        nargs="?",
        default="6ad53d96-a66b-4f9b-9787-563ecc92c6fa",
        help="Project ID or URL (default: 6ad53d96-a66b-4f9b-9787-563ecc92c6fa)",
    )
    p_msg.add_argument(
        "--limit",
        "-l",
        type=int,
        default=15,
        help="Number of recent tasks to fetch for selection (default: 15)",
    )
    p_msg.add_argument(
        "--task-id",
        "-t",
        default=None,
        help="Directly output commit message for a specific task ID",
    )
    p_msg.add_argument(
        "--latest",
        action="store_true",
        help="Directly use latest task without interactive selector",
    )
    p_msg.add_argument(
        "--commit",
        "-c",
        action="store_true",
        help="Stage changes and commit directly instead of printing to stdout",
    )
    p_msg.add_argument(
        "--no-push",
        action="store_true",
        help="Do not git push after commit (used with --commit)",
    )

    # 5. watch_branches
    p_wb = subparsers.add_parser(
        "watch_branches",
        aliases=["wb"],
        help="Watch multiple branch:project pairs, checkout branch, pull when completed, and commit",
    )
    p_wb.add_argument(
        "--branch",
        "-b",
        action="append",
        required=True,
        dest="branch_specs",
        metavar="BRANCH:TARGET",
        help="Branch to project mapping, e.g. -b main:6ad53... -b wip:https://...",
    )
    p_wb.add_argument(
        "paths",
        nargs="*",
        help="Paths to sync (positional or via --paths)",
    )
    p_wb.add_argument(
        "--paths",
        nargs="+",
        dest="opt_paths",
        help="Paths to sync (e.g. --paths LeanScript/ lakefile.toml)",
    )
    p_wb.add_argument(
        "--interval",
        "-i",
        type=int,
        default=60,
        help="Poll interval in seconds (default: 60)",
    )
    p_wb.add_argument(
        "--no-push",
        action="store_true",
        help="Do not git push after commit",
    )

    args = parser.parse_args()

    raw_project = getattr(args, "project", None)
    project_id = parse_project_id(raw_project) if raw_project else None
    if args.command != "watch_branches":
        setup_auth(project_id)

    if args.command in (
        "last_3_tasks_my_prompts_and_its_end_message",
        "last3",
        "status",
    ):
        asyncio.run(cmd_last_3_tasks(project_id))

    elif args.command == "pull_force":
        execute_pull(project_id, args.paths)

    elif args.command == "watch_and_pull":
        sync_paths = args.opt_paths or args.paths
        if not sync_paths:
            parser.error("At least one path to sync is required.")
        asyncio.run(
            cmd_watch_and_pull(
                project_id, sync_paths, args.interval, args.no_push
            )
        )

    elif args.command in (
        "task_to_git_message",
        "completed_task_to_git_message",
        "commit_msg",
        "msg",
    ):
        asyncio.run(
            cmd_task_to_git_message(
                project_id,
                limit=args.limit,
                task_id=args.task_id,
                latest=args.latest,
                commit=args.commit,
                no_push=args.no_push,
            )
        )

    elif args.command in ("watch_branches", "wb"):
        sync_paths = args.opt_paths or args.paths
        if not sync_paths:
            parser.error("At least one path to sync is required.")

        targets = []
        for spec in args.branch_specs:
            if ":" not in spec:
                parser.error(
                    f"Invalid format '{spec}'. Use --branch <branch_name>:<project_id_or_url>"
                )
            b_name, target_raw = spec.split(":", 1)
            targets.append(
                BranchTarget(
                    branch=b_name.strip(),
                    project_id=parse_project_id(target_raw.strip()),
                    raw_target=target_raw.strip(),
                )
            )

        asyncio.run(
            cmd_watch_branches(
                targets=targets,
                paths=sync_paths,
                interval=args.interval,
                no_push=args.no_push,
            )
        )


if __name__ == "__main__":
    main()
