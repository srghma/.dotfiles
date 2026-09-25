#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "aristotlelib",
#     "pydantic>=2.0.0",
#     "rich>=13.0.0",
#     "readchar>=4.0.0",
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
import subprocess
import sys
import tempfile
from typing import Any, Callable

from pydantic import BaseModel, Field, field_validator
import readchar
from readchar import key as K
from rich.console import Console, Group
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

import aristotlelib
from aristotlelib import AgentTask, Project, set_api_key
import aristotlelib.api_request
import aristotlelib.aristotle_object

console = Console()
err_console = Console(stderr=True)

CACHE_DIR = Path.home() / ".cache" / "aristotle"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

TERMINAL_STATUSES = {
    "COMPLETE",
    "COMPLETE_WITH_ERRORS",
    "FAILED",
    "CANCELLED",
    "ERROR",
}
NON_USER_EVENT_TYPES = {2, 3, 4, 5, 6, 7, 8, 9, 16}


# ─────────────────────────────────────────────────────────────────────────────
# Config Models (Pydantic)
# ─────────────────────────────────────────────────────────────────────────────


def parse_project_id(target: str | None) -> str:
    """Extracts raw UUID if given an Aristotle web URL or returns the UUID directly."""
    if not target:
        return ""
    target_str = str(target).strip()
    match = re.search(r"projects/([0-9a-fA-F-]{36})", target_str)
    if match:
        return match.group(1)
    match_uuid = re.search(
        r"([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})",
        target_str,
    )
    if match_uuid:
        return match_uuid.group(1)
    return target_str


class BranchConfig(BaseModel):
    project_id: str
    paths: list[str] | None = None
    push: bool | None = None
    commit: bool | None = None

    @field_validator("project_id", mode="before")
    @classmethod
    def _clean_project_id(cls, v: Any) -> str:
        return parse_project_id(str(v))


class RepoConfig(BaseModel):
    interval: int = 60
    push: bool = True
    commit: bool = True
    paths: list[str] = Field(default_factory=list)
    branches: dict[str, BranchConfig] = Field(default_factory=dict)

    @field_validator("branches", mode="before")
    @classmethod
    def _coerce_branches(cls, v: Any) -> dict[str, Any]:
        if not isinstance(v, dict):
            return {}
        normalized = {}
        for b_name, b_val in v.items():
            if isinstance(b_val, str):
                normalized[b_name] = {"project_id": b_val}
            else:
                normalized[b_name] = b_val
        return normalized


class AristotleConfig(BaseModel):
    project_id_to_key: dict[str, str] = Field(default_factory=dict)
    repos: dict[Path, RepoConfig] = Field(default_factory=dict)

    @field_validator("project_id_to_key", mode="before")
    @classmethod
    def _clean_keys(cls, v: Any) -> dict[str, str]:
        if not isinstance(v, dict):
            return {}
        return {parse_project_id(str(k)): str(val) for k, val in v.items()}

    @field_validator("repos", mode="before")
    @classmethod
    def _resolve_repo_paths(cls, v: Any) -> dict[str, Any]:
        if not isinstance(v, dict):
            return {}
        resolved = {}
        for r_path, r_cfg in v.items():
            exp = Path(os.path.expandvars(os.path.expanduser(str(r_path).strip()))).resolve()
            resolved[str(exp)] = r_cfg  # <-- Fix: return str, Pydantic casts to Path
        return resolved


def load_config() -> AristotleConfig:
    """Loads configuration from MYARISTOTLE_CONFIG with backward compatibility."""
    raw = os.environ.get("MYARISTOTLE_CONFIG", "").strip()
    if raw:
        try:
            expanded = os.path.expandvars(os.path.expanduser(raw))
            data = json.loads(expanded)
            return AristotleConfig.model_validate(data)
        except Exception as e:
            err_console.print(f"[yellow]⚠️  Warning: Failed to parse MYARISTOTLE_CONFIG: {e}[/yellow]")

    # Legacy fallback
    p_to_k = {}
    legacy_keys = os.environ.get("ARISTOTLE_PROJECT_ID_TO_KEY")
    if legacy_keys:
        try:
            p_to_k = {parse_project_id(k): v for k, v in json.loads(legacy_keys).items()}
        except Exception:
            pass

    repos_dict: dict[Path, Any] = {}
    legacy_repos = os.environ.get("ARISTOTLE_REPO_LOCATION_AND_BRANCH_TO_PROJECT_ID", "").strip()
    if legacy_repos:
        for line in legacy_repos.splitlines():
            line = os.path.expandvars(os.path.expanduser(line.strip()))
            if not line or line.startswith("#") or "=" not in line:
                continue
            target_key, proj = line.split("=", 1)
            if ":" in target_key:
                r_part, b_part = target_key.rsplit(":", 1)
                r_path = Path(r_part.strip()).resolve()
                repos_dict.setdefault(r_path, {"branches": {}})["branches"][b_part.strip()] = proj.strip()

    return AristotleConfig(project_id_to_key=p_to_k, repos=repos_dict)


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
    repo_dir: Path
    repo_name: str
    paths: list[str] | None = None
    push: bool = True
    commit: bool = True


def update_aristotle_client_auth(api_key: str):
    os.environ["ARISTOTLE_API_KEY"] = api_key
    try:
        set_api_key(api_key)
    except Exception:
        pass

    for mod in (aristotlelib, aristotlelib.api_request, aristotlelib.aristotle_object):
        for attr in ("api_key", "API_KEY", "_api_key"):
            if hasattr(mod, attr):
                setattr(mod, attr, api_key)

    primary_client = getattr(aristotlelib.api_request, "client", None)
    if primary_client is not None:
        try:
            new_c = type(primary_client)()
            for attr in ("api_key", "_api_key"):
                setattr(new_c, attr, api_key)
            if hasattr(new_c, "headers") and new_c.headers is not None:
                new_c.headers["Authorization"] = f"Bearer {api_key}"
            aristotlelib.api_request.client = new_c
            aristotlelib.aristotle_object.client = new_c
        except Exception:
            pass


def setup_auth(project_id: str | None = None) -> str:
    cfg = load_config()
    clean_pid = parse_project_id(project_id) if project_id else None

    api_key = None
    if clean_pid and clean_pid in cfg.project_id_to_key:
        val = cfg.project_id_to_key[clean_pid]
        api_key = os.environ.get(val[1:] if val.startswith("$") else val, val)

    if not api_key:
        api_key = os.environ.get("ARISTOTLE_API_KEY")

    if not api_key:
        err_console.print(
            f"[red]Error: Could not determine Aristotle API key for project '{clean_pid or 'unknown'}'.[/red]\n"
            f"Configured project IDs in MYARISTOTLE_CONFIG: {list(cfg.project_id_to_key.keys())}"
        )
        sys.exit(1)

    update_aristotle_client_auth(api_key)
    return api_key


def extract_status_str(status_raw: Any) -> str:
    return str(getattr(status_raw, "value", status_raw)).split(".")[-1]


def status_badge(status_raw: Any, percent: int | None = None) -> Text:
    s = extract_status_str(status_raw)
    pct = f" ({percent}%)" if percent is not None and "PROGRESS" in s else ""
    if "PROGRESS" in s:
        return Text.from_markup(f"[yellow]🔄 {s}{pct}[/yellow]")
    if "ERROR" in s:
        return Text.from_markup(f"[red]⚠️  {s}[/red]")
    if "COMPLETE" in s or "SUCCESS" in s:
        return Text.from_markup(f"[green]✅ {s}[/green]")
    if "FAIL" in s:
        return Text.from_markup(f"[red]❌ {s}[/red]")
    if "QUEUE" in s:
        return Text.from_markup(f"[blue]⏳ {s}[/blue]")
    return Text.from_markup(f"[dim]ℹ️  {s}{pct}[/dim]")


def extract_task_id(task: Any) -> str | None:
    if isinstance(task, dict):
        return task.get("agent_task_id") or task.get("id") or task.get("object_id")
    for attr in ("agent_task_id", "id", "object_id"):
        val = getattr(task, attr, None)
        if val:
            return str(val)
    if hasattr(task, "model_dump"):
        try:
            d = task.model_dump()
            return d.get("agent_task_id") or d.get("id") or d.get("object_id")
        except Exception:
            pass
    return None


async def fetch_project_tasks(project: Project, limit: int = 10):
    res = project.get_tasks(limit=limit)
    if inspect.isawaitable(res):
        res = await res
    if isinstance(res, tuple):
        return res[0]
    if hasattr(res, "tasks"):
        return res.tasks
    return res if isinstance(res, list) else [res]


# ─────────────────────────────────────────────────────────────────────────────
# Git & Prompt Helpers
# ─────────────────────────────────────────────────────────────────────────────


def get_current_git_repo_and_branch(cwd: Path | None = None) -> tuple[Path | None, str | None]:
    cwd = (cwd or Path.cwd()).resolve()
    try:
        res_root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            cwd=cwd,
        )
        if res_root.returncode != 0:
            return None, None
        repo_root = Path(res_root.stdout.strip()).resolve()

        res_branch = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            cwd=cwd,
        )
        branch = res_branch.stdout.strip() or None
        return repo_root, branch
    except Exception:
        return None, None


def resolve_project_id(target: str | None = None, cwd: Path | None = None) -> str:
    cwd = (cwd or Path.cwd()).resolve()
    clean_target = parse_project_id(target)
    if clean_target and len(clean_target) == 36 and clean_target.count("-") == 4:
        return clean_target

    cfg = load_config()
    repo_root, current_branch = get_current_git_repo_and_branch(cwd)

    if repo_root and repo_root in cfg.repos:
        repo_cfg = cfg.repos[repo_root]
        check_branch = target or current_branch
        if check_branch and check_branch in repo_cfg.branches:
            return repo_cfg.branches[check_branch].project_id

    if clean_target:
        return clean_target

    err_console.print(
        f"[red]Error: Could not determine Aristotle project ID for {repo_root or cwd}.[/red]\n"
        f"Branch: {current_branch or 'unknown'}\n"
        f"Please specify a project ID or configure MYARISTOTLE_CONFIG."
    )
    sys.exit(1)


def extract_first_line_prompt(prompt: str | None, max_chars: int = 60) -> str:
    if not prompt or not prompt.strip():
        return ""
    for raw_line in prompt.strip().splitlines():
        line = re.sub(r"^([#\-*> ]+)", "", raw_line.strip())
        if re.match(r"^You wrote\b", line, re.IGNORECASE):
            continue
        if line:
            return (line[: max_chars - 3].rsplit(" ", 1)[0] + "...") if len(line) > max_chars else line
    return ""


def build_git_commit_message(task: TaskInfo) -> str:
    pr_clean = task.prompt.strip() if task.prompt else ""
    first_line = extract_first_line_prompt(pr_clean, max_chars=60)
    commit_title = f"Aristotle: {task.task_id[:8]} ({task.status})"
    if first_line:
        commit_title += f" - {first_line}"

    lines = [
        commit_title,
        "",
        f"Task ID: {task.task_id}",
        f"Status:  {task.status}",
        "",
        "=== My Prompt ===",
        pr_clean or "(No prompt recorded)",
    ]

    if task.status in TERMINAL_STATUSES:
        lines.extend([
            "",
            "=== Aristotle End Message ===",
            task.end_msg.strip() if task.end_msg else "(No end message)",
        ])

    return "\n".join(lines)


def is_task_in_git(task_id: str, branch: str | None = None, cwd: Path | None = None) -> bool:
    cwd = (cwd or Path.cwd()).resolve()
    try:
        cmd = ["git", "log"]
        if branch:
            cmd.append(branch)
        cmd.extend(["-n", "50", f"--grep=Task ID: {task_id}"])
        res = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
        return res.returncode == 0 and bool(res.stdout.strip())
    except Exception:
        return False


def git_checkout(branch: str, cwd: Path | None = None) -> bool:
    cwd = (cwd or Path.cwd()).resolve()

    # 1. Check current branch first — if already on it, no checkout needed!
    curr = subprocess.run(
        ["git", "branch", "--show-current"],
        capture_output=True,
        text=True,
        cwd=cwd,
    ).stdout.strip()
    if curr == branch:
        return True

    # 2. Only if we actually need to switch branches, ensure working tree is clean
    status = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True,
        text=True,
        cwd=cwd,
    ).stdout.strip()
    if status:
        err_console.print(
            f"[red]⚠️ Cannot switch to '{branch}' in {cwd}: uncommitted changes.[/red]\n"
            f"[dim]{status}[/dim]"
        )
        return False

    res = subprocess.run(["git", "checkout", branch], capture_output=True, text=True, cwd=cwd)
    return res.returncode == 0


def git_commit_changes(commit_msg: str, push: bool = True, cwd: Path | None = None) -> bool:
    cwd = (cwd or Path.cwd()).resolve()
    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, cwd=cwd).stdout.strip()
    if not status:
        console.print(f"[dim][{cwd.name}] No git working tree changes detected.[/dim]")
        return False

    console.print(f"[bold green]📝 [{cwd.name}] Changes detected. Committing...[/bold green]")
    subprocess.run(["git", "add", "."], check=True, cwd=cwd)
    subprocess.run(["git", "commit", "-m", commit_msg], check=True, cwd=cwd)

    if push:
        console.print(f"[bold blue]🚀 [{cwd.name}] Pushing to remote...[/bold blue]")
        try:
            subprocess.run(["git", "push"], check=True, cwd=cwd)
        except subprocess.CalledProcessError as e:
            err_console.print(f"[red]⚠️ Git push failed in {cwd}: {e}[/red]")
            return False
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Task Caching & Extraction Helpers
# ─────────────────────────────────────────────────────────────────────────────


def load_task_cache(task_id: str) -> dict | None:
    f = CACHE_DIR / f"{task_id}.json"
    if f.exists():
        try:
            return json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            return None
    return None


def save_task_cache(task_id: str, data: dict):
    f = CACHE_DIR / f"{task_id}.json"
    try:
        f.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    except Exception:
        pass


def get_synced_tasks(project_id: str) -> set[str]:
    f = CACHE_DIR / f"synced_{project_id}.json"
    if f.exists():
        try:
            return set(json.loads(f.read_text(encoding="utf-8")).get("synced_task_ids", []))
        except Exception:
            return set()
    return set()


def mark_task_synced(project_id: str, task_id: str):
    synced = get_synced_tasks(project_id)
    synced.add(task_id)
    f = CACHE_DIR / f"synced_{project_id}.json"
    try:
        f.write_text(json.dumps({"synced_task_ids": sorted(list(synced))}, indent=2), encoding="utf-8")
    except Exception:
        pass


async def extract_prompt_from_task(task: Any) -> str:
    if not task:
        return ""
    for attr in ("prompt", "initial_prompt", "user_prompt", "input", "description", "name"):
        val = getattr(task, attr, None)
        if isinstance(val, str) and val.strip() and not val.strip().endswith("..."):
            return val.strip()
    return ""


async def get_task_info(task_obj: Any, task_id: str | None = None) -> TaskInfo | None:
    t_id = task_id or extract_task_id(task_obj)
    if not t_id:
        return None

    raw_status = getattr(task_obj, "status", "")
    status_str = extract_status_str(raw_status)
    pct = getattr(task_obj, "percent_complete", None)
    created_at = str(getattr(task_obj, "created_at", "N/A"))

    cached = load_task_cache(t_id)
    if cached and cached.get("status") in TERMINAL_STATUSES and cached.get("prompt"):
        return TaskInfo(
            task_id=t_id,
            status=status_str,
            raw_status=raw_status,
            percent=pct,
            created_at=created_at,
            prompt=cached["prompt"],
            end_msg=cached.get("output_summary"),
            is_terminal=(status_str in TERMINAL_STATUSES),
            from_cache=True,
            task_obj=task_obj,
        )

    end_msg = getattr(task_obj, "output_summary", None)
    prompt = await extract_prompt_from_task(task_obj)

    if not prompt:
        try:
            full_task = await AgentTask.from_id(t_id)
            prompt = await extract_prompt_from_task(full_task)
            end_msg = end_msg or getattr(full_task, "output_summary", None)
        except Exception:
            pass

    if status_str in TERMINAL_STATUSES:
        save_task_cache(t_id, {"task_id": t_id, "status": status_str, "prompt": prompt, "output_summary": end_msg})

    return TaskInfo(
        task_id=t_id,
        status=status_str,
        raw_status=raw_status,
        percent=pct,
        created_at=created_at,
        prompt=prompt,
        end_msg=end_msg,
        is_terminal=(status_str in TERMINAL_STATUSES),
        from_cache=False,
        task_obj=task_obj,
    )


async def fetch_tasks_info(raw_tasks: list, on_progress: Callable[[int, int], None] | None = None) -> list[TaskInfo]:
    sem = asyncio.Semaphore(5)
    total = len(raw_tasks)
    done = 0

    async def _load(t):
        nonlocal done
        async with sem:
            info = await get_task_info(t)
        done += 1
        if on_progress:
            on_progress(done, total)
        return info

    results = await asyncio.gather(*(_load(t) for t in raw_tasks))
    return [r for r in results if r is not None]


# ─────────────────────────────────────────────────────────────────────────────
# Interactive Task Selector (Rich + readchar)
# ─────────────────────────────────────────────────────────────────────────────


def select_task_interactive(tasks_info: list[TaskInfo], project_id: str) -> TaskInfo | None:
    if not sys.stdin.isatty():
        return tasks_info[0] if tasks_info else None

    selected_idx = 0

    def render_ui() -> Panel:
        table = Table(box=None, expand=True, show_header=True, header_style="bold dim")
        table.add_column("", width=3)
        table.add_column("Status", width=16)
        table.add_column("Task ID", width=10)
        table.add_column("Created", width=12)
        table.add_column("Prompt", overflow="ellipsis")

        for idx, item in enumerate(tasks_info):
            is_sel = idx == selected_idx
            prefix = "[bold cyan]❯[/bold cyan]" if is_sel else " "
            style = "bold cyan" if is_sel else ""
            created_short = item.created_at[5:16] if len(item.created_at) >= 16 else item.created_at
            first_line = extract_first_line_prompt(item.prompt, max_chars=50)

            table.add_row(
                prefix,
                status_badge(item.raw_status, item.percent),
                Text(item.task_id[:8], style=style),
                Text(created_short, style="dim"),
                Text(first_line, style=style),
            )

        cur = tasks_info[selected_idx]
        details = Table.grid(padding=(0, 2))
        details.add_column(style="bold")
        details.add_column()
        details.add_row("Task ID:", f"[cyan]{cur.task_id}[/cyan]")
        details.add_row("Status:", status_badge(cur.raw_status, cur.percent))
        details.add_row("Created:", f"[dim]{cur.created_at}[/dim]")

        preview_group: list[Any] = [
            table,
            Text("─" * 40, style="dim"),
            details,
            Text("\n📥 My Prompt:", style="bold cyan"),
            Panel(cur.prompt.strip() or "(No prompt)", border_style="dim", expand=True),
        ]

        if cur.is_terminal and cur.end_msg:
            preview_group.extend([
                Text("📤 Aristotle Response:", style="bold green"),
                Panel(cur.end_msg.strip(), border_style="dim", expand=True),
            ])

        preview_group.append(
            Text(
                "\n[↑/k] Up  [↓/j] Down  [1-9] Jump  [Enter] Select & Commit  [q/Esc] Cancel",
                style="dim italic",
            )
        )

        return Panel(
            Group(*preview_group),
            title=f"[bold magenta]🧠 Aristotle Task Selector[/bold magenta] [dim]• {project_id}[/dim]",
            border_style="cyan",
        )

    with Live(render_ui(), console=console, screen=True, auto_refresh=False) as live:
        while True:
            live.update(render_ui(), refresh=True)
            k = readchar.readkey()

            if k in (K.UP, "k", "K"):
                selected_idx = max(0, selected_idx - 1)
            elif k in (K.DOWN, "j", "J"):
                selected_idx = min(len(tasks_info) - 1, selected_idx + 1)
            elif k in (K.ENTER, K.CR):
                return tasks_info[selected_idx]
            elif k in (K.ESC, "q", "Q", K.CTRL_C, K.CTRL_D):
                return None
            elif k.isdigit() and 1 <= int(k) <= len(tasks_info):
                selected_idx = int(k) - 1


# ─────────────────────────────────────────────────────────────────────────────
# Sync & Pull Logic
# ─────────────────────────────────────────────────────────────────────────────


def collect_rsync_excludes_for_git(cwd: Path) -> list[str]:
    excludes = ["/.git/", "/.git", "/.gitignore", "/.gitattributes", "/.gitmodules"]
    root_gi = cwd / ".gitignore"
    if root_gi.is_file():
        try:
            for line in root_gi.read_text(encoding="utf-8", errors="replace").splitlines():
                clean = line.strip()
                if clean and not clean.startswith(("#", "!")) and clean not in excludes:
                    excludes.append(clean)
        except Exception:
            pass
    return excludes


def execute_pull(project_id: str, paths: list[str] | None = None, cwd: Path | None = None) -> bool:
    paths = paths or []
    cwd = (cwd or Path.cwd()).resolve()
    api_key = setup_auth(project_id)

    console.print(f"[bold blue]==> [{cwd.name}] Downloading Aristotle project:[/bold blue] [cyan]{project_id}[/cyan] ...")

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        archive_path = tmp_path / "archive.tar.gz"
        extracted_path = tmp_path / "extracted"
        extracted_path.mkdir(parents=True, exist_ok=True)

        cmd = ["aristotle", "download", project_id, "--destination", str(archive_path)]
        if not shutil.which("aristotle"):
            cmd = ["uv", "run", "--with", "aristotlelib", "aristotle", "download", project_id, "--destination", str(archive_path)]

        env = dict(os.environ, ARISTOTLE_API_KEY=api_key)
        res = subprocess.run(cmd, capture_output=True, text=True, env=env)
        if res.returncode != 0:
            err_console.print(f"[red]Download failed:\n{res.stderr or res.stdout}[/red]")
            return False

        subprocess.run(["tar", "-xzf", str(archive_path), "-C", str(extracted_path)], check=True)

        root_path = extracted_path
        subdirs = [d for d in extracted_path.iterdir() if d.is_dir() and not d.name.startswith(".")]
        if paths:
            first_clean = paths[0].strip("/")
            if not (extracted_path / first_clean).exists():
                for s in subdirs:
                    if (s / first_clean).exists():
                        root_path = s
                        break
        elif len(subdirs) == 1:
            root_path = subdirs[0]

        excludes = collect_rsync_excludes_for_git(cwd)
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as ef:
            ef.write("\n".join(excludes))
            exclude_file = Path(ef.name)

        try:
            if not paths:
                rsync_cmd = ["rsync", "-av", "--delete", f"--exclude-from={exclude_file}", f"{root_path}/", f"{cwd}/"]
                subprocess.run(rsync_cmd, check=True)
            else:
                for p_str in paths:
                    clean_p = p_str.strip("/")
                    src, dst = root_path / clean_p, cwd / clean_p
                    if not src.exists():
                        continue
                    if src.is_dir():
                        dst.mkdir(parents=True, exist_ok=True)
                        subprocess.run(["rsync", "-av", "--delete", f"--exclude-from={exclude_file}", f"{src}/", f"{dst}/"], check=True)
                    else:
                        dst.parent.mkdir(parents=True, exist_ok=True)
                        subprocess.run(["rsync", "-av", str(src), str(dst)], check=True)
        finally:
            exclude_file.unlink(missing_ok=True)

    console.print(f"[green]==> [{cwd.name}] Sync complete![/green]\n")
    return True


# ─────────────────────────────────────────────────────────────────────────────
# Commands
# ─────────────────────────────────────────────────────────────────────────────


async def cmd_last_3_tasks(project_id: str):
    setup_auth(project_id)
    project = await Project.from_id(project_id)
    raw_tasks = await fetch_project_tasks(project, limit=3)
    tasks_info = await fetch_tasks_info(raw_tasks)

    console.print(f"\n[bold magenta]🚀 Aristotle Project:[/bold magenta] [cyan]{project_id}[/cyan]\n")
    for t in tasks_info:
        badge = status_badge(t.raw_status, t.percent)
        console.print(Panel(
            Group(
                Text(f"Status:  {t.status}", style="bold"),
                Text(f"Created: {t.created_at}", style="dim"),
                Text("\n📥 Prompt:\n" + (t.prompt.strip() or "(None)"), style="cyan"),
                Text(f"\n📤 Aristotle Response:\n{t.end_msg.strip() if t.end_msg else '(None)'}", style="green"),
            ),
            title=f"Task {t.task_id}",
            subtitle=badge.plain,
            border_style="magenta",
        ))


async def cmd_watch_branches(targets: list[BranchTarget], interval: int = 60):
    console.print("\n[bold magenta]👀 Aristotle Multi-Repository Watcher Started[/bold magenta]")
    table = Table(show_header=True, header_style="bold dim")
    table.add_column("Repository : Branch")
    table.add_column("Aristotle Project ID")
    table.add_column("Sync Paths")
    table.add_column("Commit/Push")

    for t in targets:
        p_desc = ", ".join(t.paths) if t.paths else "(all non-gitignored)"
        flags = [f"commit={'on' if t.commit else 'off'}", f"push={'on' if t.push else 'off'}"]
        table.add_row(f"[cyan]{t.repo_name}:{t.branch}[/cyan]", t.project_id, p_desc, ", ".join(flags))

    console.print(table)
    console.print(f"[bold]Poll interval:[/bold] {interval}s\n")

    max_len = max(len(f"{t.repo_name}:{t.branch}") for t in targets) if targets else 15

    try:
        while True:
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            for t in targets:
                setup_auth(t.project_id)
                synced_task_ids = get_synced_tasks(t.project_id)
                tag = f"{t.repo_name}:{t.branch}"

                try:
                    project = await Project.from_id(t.project_id)
                    tasks = await fetch_project_tasks(project, limit=10)
                except Exception as e:
                    console.print(f"[{now_str}] [{tag}] [red]⚠️ Error fetching tasks: {e}[/red]")
                    continue

                if not tasks:
                    continue

                latest_terminal = next(
                    (task for task in tasks if extract_status_str(getattr(task, "status", "")) in TERMINAL_STATUSES),
                    None,
                )

                synced_something = False
                if latest_terminal:
                    term_id = extract_task_id(latest_terminal)
                    is_synced = (term_id in synced_task_ids) or (
                        t.commit and is_task_in_git(term_id, t.branch, cwd=t.repo_dir)
                    )

                    if not is_synced:
                        task_info = await get_task_info(latest_terminal, term_id)
                        if not task_info:
                            continue

                        console.print(f"\n[{now_str}] [bold cyan][{tag}][/bold cyan] Finished task [cyan]{term_id}[/cyan]")
                        if not git_checkout(t.branch, cwd=t.repo_dir):
                            continue

                        if not execute_pull(t.project_id, t.paths, cwd=t.repo_dir):
                            continue

                        if t.commit:
                            commit_msg = build_git_commit_message(task_info)
                            git_commit_changes(commit_msg, push=t.push, cwd=t.repo_dir)
                        else:
                            console.print(f"[dim]Commit skipped for [{tag}] (commit=off).[/dim]")

                        mark_task_synced(t.project_id, term_id)
                        synced_something = True

                if not synced_something:
                    latest = tasks[0]
                    t_id = extract_task_id(latest) or "unknown"
                    st = extract_status_str(getattr(latest, "status", ""))
                    if st not in TERMINAL_STATUSES:
                        badge = status_badge(getattr(latest, "status", ""), getattr(latest, "percent_complete", None))
                        console.print(f"[dim][{now_str}][/dim] [{tag:<{max_len}}] ⏳ Task [cyan]{t_id[:8]}[/cyan]... {badge}")

            await asyncio.sleep(interval)

    except (KeyboardInterrupt, asyncio.CancelledError):
        console.print("\n[yellow]Watcher stopped by user.[/yellow]")


# ─────────────────────────────────────────────────────────────────────────────
# CLI Entrypoint
# ─────────────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(description="myaristotle - Aristotle task viewer, puller, and watcher")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # 1. status / last3
    p_last = subparsers.add_parser("last_3_tasks_my_prompts_and_its_end_message", aliases=["last3", "status"])
    p_last.add_argument("project", nargs="?", default=None)

    # 2. pull_force
    p_pull = subparsers.add_parser("pull_force")
    p_pull.add_argument("project", nargs="?", default=None)
    p_pull.add_argument("paths", nargs="*", default=[])
    p_pull.add_argument("--paths", nargs="+", dest="opt_paths", default=None)

    # 3. watch_and_pull
    p_watch = subparsers.add_parser("watch_and_pull")
    p_watch.add_argument("project", nargs="?", default=None)
    p_watch.add_argument("paths", nargs="*", default=[])
    p_watch.add_argument("--paths", nargs="+", dest="opt_paths", default=None)
    p_watch.add_argument("--interval", "-i", type=int, default=None)
    p_watch.add_argument("--no-push", action="store_true", default=None)
    p_watch.add_argument("--no-commit", action="store_true", default=None)

    # 4. commit_msg
    p_msg = subparsers.add_parser("task_to_git_message", aliases=["commit_msg", "msg"])
    p_msg.add_argument("project", nargs="?", default=None)
    p_msg.add_argument("--limit", "-l", type=int, default=15)
    p_msg.add_argument("--task-id", "-t", default=None)
    p_msg.add_argument("--latest", action="store_true")
    p_msg.add_argument("--commit", "-c", action="store_true")
    p_msg.add_argument("--no-push", action="store_true")

    # 5. watch_branches
    p_wb = subparsers.add_parser("watch_branches", aliases=["wb"])
    p_wb.add_argument("--branch", "-b", action="append", dest="branch_specs")
    p_wb.add_argument("--current", action="store_true", help="Only watch current repo")
    p_wb.add_argument("paths", nargs="*", default=[])
    p_wb.add_argument("--paths", nargs="+", dest="opt_paths", default=None)
    p_wb.add_argument("--interval", "-i", type=int, default=None)
    p_wb.add_argument("--no-push", action="store_true", default=None)
    p_wb.add_argument("--no-commit", action="store_true", default=None)

    args = parser.parse_args()
    cfg = load_config()
    repo_root, _ = get_current_git_repo_and_branch()
    repo_cfg = cfg.repos.get(repo_root) if repo_root else None

    if args.command in ("last_3_tasks_my_prompts_and_its_end_message", "last3", "status"):
        pid = resolve_project_id(args.project)
        asyncio.run(cmd_last_3_tasks(pid))

    elif args.command == "pull_force":
        pid = resolve_project_id(args.project)
        sync_paths = args.opt_paths if args.opt_paths is not None else args.paths
        if not sync_paths and repo_cfg:
            sync_paths = repo_cfg.paths
        execute_pull(pid, sync_paths, cwd=repo_root)

    elif args.command in ("task_to_git_message", "commit_msg", "msg"):
        pid = resolve_project_id(args.project)
        setup_auth(pid)
        if args.task_id:
            info = asyncio.run(get_task_info(None, args.task_id))
            chosen = info
        else:
            proj = asyncio.run(Project.from_id(pid))
            raw = asyncio.run(fetch_project_tasks(proj, limit=args.limit))
            infos = asyncio.run(fetch_tasks_info(raw))
            chosen = infos[0] if args.latest else select_task_interactive(infos, pid)

        if not chosen:
            console.print("[yellow]Cancelled.[/yellow]")
            return

        msg = build_git_commit_message(chosen)
        if args.commit:
            git_commit_changes(msg, push=(not args.no_push), cwd=repo_root)
        else:
            print(msg)

    elif args.command in ("watch_branches", "wb"):
        cli_paths = args.opt_paths if args.opt_paths is not None else (args.paths if args.paths else None)
        targets: list[BranchTarget] = []
        intervals = []

        if args.branch_specs:
            for spec in args.branch_specs:
                b_name, target_raw = spec.split(":", 1) if ":" in spec else (spec, "")
                proj = parse_project_id(target_raw) or (repo_cfg.branches[b_name].project_id if repo_cfg and b_name in repo_cfg.branches else "")
                t_dir = repo_root or Path.cwd()
                targets.append(BranchTarget(
                    branch=b_name.strip(),
                    project_id=proj,
                    raw_target=spec,
                    repo_dir=t_dir,
                    repo_name=t_dir.name,
                    paths=cli_paths or (repo_cfg.paths if repo_cfg else []),
                    push=False if args.no_push else (repo_cfg.push if repo_cfg else True),
                    commit=False if args.no_commit else (repo_cfg.commit if repo_cfg else True),
                ))
        else:
            search_repos = {repo_root: repo_cfg} if (args.current and repo_root and repo_cfg) else cfg.repos
            for r_dir, r_conf in search_repos.items():
                if not r_dir.is_dir():
                    continue
                intervals.append(r_conf.interval)
                for b_name, b_conf in r_conf.branches.items():
                    targets.append(BranchTarget(
                        branch=b_name,
                        project_id=b_conf.project_id,
                        raw_target=f"{r_dir.name}:{b_name}",
                        repo_dir=r_dir,
                        repo_name=r_dir.name,
                        paths=cli_paths if cli_paths is not None else (b_conf.paths if b_conf.paths is not None else r_conf.paths),
                        push=False if args.no_push else (b_conf.push if b_conf.push is not None else r_conf.push),
                        commit=False if args.no_commit else (b_conf.commit if b_conf.commit is not None else r_conf.commit),
                    ))

        if not targets:
            err_console.print("[red]No configured targets found to watch in MYARISTOTLE_CONFIG.[/red]")
            sys.exit(1)

        poll_interval = args.interval if args.interval is not None else (min(intervals) if intervals else 60)
        asyncio.run(cmd_watch_branches(targets, interval=poll_interval))


if __name__ == "__main__":
    main()
