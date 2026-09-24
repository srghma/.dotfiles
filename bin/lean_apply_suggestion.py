#!/usr/bin/env python3
"""
Lean 4 automated fixer for:
  - Deprecations (`if_pos` -> `ite_eq_left`)
  - Proposition definitions (`def` -> `theorem`)
  - Semireducible class instances (`@[instance_reducible]`)
  - Unreachable tactics (comments out dead tactics)
  - Unused variables (`[apply] _var`)

Usage:
  lake --ansi build <targets> 2>&1 | python3 lean_apply_suggestion.py -p
  lake --ansi build <targets> 2>&1 | python3 lean_apply_suggestion.py -p --dry-run
"""

import sys
import os
import re
import argparse
from collections import defaultdict

ANSI_ESCAPE = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')

# 1. Deprecations
DEPR_REGEX = re.compile(
    r"(?:warning:\s+)?(?P<file>(?:[a-zA-Z]:)?[^:\r\n\s]+):(?P<line>\d+):(?P<col>\d+):"
    r"(?:\s*warning:)?"
    r"\s*[`'\"]?(?P<old>[^`'\"\s]+)[`'\"]?\s+has been deprecated[:,\s]+"
    r"(?:[Uu]se\s+)?(?:`(?P<new_b>[^`]+)`|'(?P<new_s>[^']+)'|(?P<new_raw>[^\s,.]+))"
    r"(?:\s+instead)?\.?",
    re.IGNORECASE
)

# 2. DefProp (def -> theorem)
DEF_PROP_REGEX = re.compile(
    r"(?:warning:\s+)?(?P<file>(?:[a-zA-Z]:)?[^:\r\n\s]+):(?P<line>\d+):(?P<col>\d+):"
    r"(?:\s*warning:)?"
    r"\s*Definition\s+[`'\"]?(?P<name>[^`'\"\s]+)[`'\"]?\s+is a proposition;\s*use\s+`theorem`\s+instead\s+of\s+`def`",
    re.IGNORECASE
)

# 3. Instance Reducible (@[instance_reducible])
INSTANCE_REDUCIBLE_REGEX = re.compile(
    r"(?:warning:\s+)?(?P<file>(?:[a-zA-Z]:)?[^:\r\n\s]+):(?P<line>\d+):(?P<col>\d+):"
    r"(?:\s*warning:)?"
    r"\s*Definition\s+[`'\"]?(?P<name>[^`'\"\s]+)[`'\"]?\s+of class type is semireducible",
    re.IGNORECASE
)

# 4. Unreachable tactic
UNREACHABLE_TAC_REGEX = re.compile(
    r"(?:warning:\s+)?(?P<file>(?:[a-zA-Z]:)?[^:\r\n\s]+):(?P<line>\d+):(?P<col>\d+):"
    r"(?:\s*warning:)?"
    r"\s*this tactic is never executed",
    re.IGNORECASE
)

# 5. Unused variables ([apply] _var)
UNUSED_VAR_START = re.compile(
    r"(?:warning:\s+)?(?P<file>(?:[a-zA-Z]:)?[^:\r\n\s]+):(?P<line>\d+):(?P<col>\d+):"
    r"(?:\s*warning:)?"
    r"\s*Variable name\s+[`'\"]?(?P<var>[^`'\"\s]+)[`'\"]?\s+is not explicitly referenced",
    re.IGNORECASE
)
APPLY_ACTION_REGEX = re.compile(r"^\s*\[apply\]\s+(?P<new_val>\S+)")


def fix_instance_reducible(lines: list[str], start_idx: int, decl_name: str) -> tuple[bool, int, str]:
    """
    Inserts @[instance_reducible] before the declaration, respecting existing docstrings/attributes.
    """
    short_name = decl_name.split('.')[-1]

    # Don't add if already present nearby
    for i in range(max(0, start_idx - 2), min(len(lines), start_idx + 6)):
        if "instance_reducible" in lines[i]:
            return False, -1, ""

    name_pat = r'(?:' + re.escape(decl_name) + r'|' + re.escape(short_name) + r')'
    decl_regex = re.compile(r'\b(?:def|instance)\s+' + name_pat + r'\b')

    target_idx = start_idx
    # Look ahead up to 6 lines to find the actual `def` or `instance` keyword
    for i in range(start_idx, min(len(lines), start_idx + 6)):
        if decl_regex.search(lines[i]):
            target_idx = i
            break

    if target_idx < len(lines):
        indent = re.match(r'^\s*', lines[target_idx]).group(0)
        attr_line = f"{indent}@[instance_reducible]\n"
        lines.insert(target_idx, attr_line)
        return True, target_idx, attr_line

    return False, -1, ""


def fix_def_prop(lines: list[str], start_line_idx: int, decl_name: str) -> tuple[bool, int, str, str]:
    """
    Finds `def <name>` in a small window around start_line_idx and replaces with `theorem`.
    """
    short_name = decl_name.split('.')[-1]
    name_pat = r'(?:' + re.escape(decl_name) + r'|' + re.escape(short_name) + r')'
    def_regex = re.compile(r'\bdef\s+' + name_pat + r'\b')

    max_idx = min(len(lines), start_line_idx + 6)
    for idx in range(start_line_idx, max_idx):
        line = lines[idx]
        if def_regex.search(line):
            orig = line
            lines[idx] = re.sub(r'\bdef\b', 'theorem', line, count=1)
            return True, idx, orig, lines[idx]
        if re.search(r'\bdef\s+', line) and (short_name in line or decl_name in line):
            orig = line
            lines[idx] = re.sub(r'\bdef\b', 'theorem', line, count=1)
            return True, idx, orig, lines[idx]

    if start_line_idx < len(lines):
        line = lines[start_line_idx]
        if re.search(r'\bdef\b', line):
            orig = line
            lines[start_line_idx] = re.sub(r'\bdef\b', 'theorem', line, count=1)
            return True, start_line_idx, orig, lines[start_line_idx]

    return False, -1, "", ""


def fix_unreachable_tactic(line: str, col: int, delete_line: bool) -> tuple[str, bool]:
    prefix = line[:col]
    if prefix.strip() == "":
        if delete_line:
            return "", True
        return f"{prefix}-- {line[col:]}", True
    else:
        return f"{prefix}-- {line[col:]}", True


def replace_ident_on_line(line: str, replacements: list[dict]) -> tuple[str, list[dict]]:
    unique = []
    seen = set()
    for r in replacements:
        key = (r["col"], r["old"], r["new"])
        if key not in seen:
            seen.add(key)
            unique.append(r)

    unique.sort(key=lambda r: r["col"], reverse=True)
    current_line = line
    applied = []

    for r in unique:
        old, new, col = r["old"], r["new"], r["col"]
        len_old = len(old)
        pos = None

        if 0 <= col <= len(current_line) - len_old and current_line[col:col + len_old] == old:
            pos = col
        elif 0 <= col - 1 <= len(current_line) - len_old and current_line[col - 1:col - 1 + len_old] == old:
            pos = col - 1
        else:
            pattern = re.compile(r'\b' + re.escape(old) + r'\b')
            matches = [m.start() for m in pattern.finditer(current_line)]
            if matches:
                pos = min(matches, key=lambda idx: abs(idx - col))
            else:
                idx = current_line.find(old)
                if idx != -1:
                    pos = idx

        if pos is not None:
            current_line = current_line[:pos] + new + current_line[pos + len_old:]
            applied.append(r)

    return current_line, applied


def main():
    parser = argparse.ArgumentParser(description="Fix Lean 4 deprecations and compiler suggestions.")
    parser.add_argument("log_file", nargs="?", default=None, help="Build log file (default: stdin)")
    parser.add_argument("-p", "--passthrough", action="store_true", help="Echo input lines to stdout as they arrive")
    parser.add_argument("--dry-run", action="store_true", help="Preview edits without modifying files")
    parser.add_argument("--delete-unreachable", action="store_true", help="Delete unreachable tactics instead of commenting them out")
    parser.add_argument("--no-instance-reducible", action="store_true", help="Do not add @[instance_reducible]")
    parser.add_argument("--no-def-prop", action="store_true", help="Do not convert `def` to `theorem`")
    parser.add_argument("--no-unused-vars", action="store_true", help="Do not apply `[apply] _var` fixes")
    parser.add_argument("--no-unreachable", action="store_true", help="Do not touch unreachable tactics")
    args = parser.parse_args()

    in_stream = open(args.log_file, "r", encoding="utf-8", errors="replace") if args.log_file else sys.stdin

    # Group actions by file
    tasks_by_file = defaultdict(list)
    pending_unused = None

    try:
        for raw_line in in_stream:
            if args.passthrough:
                sys.stdout.write(raw_line)
                sys.stdout.flush()

            clean = ANSI_ESCAPE.sub('', raw_line).strip()

            # 1. Instance reducible
            if not args.no_instance_reducible:
                m_inst = INSTANCE_REDUCIBLE_REGEX.search(clean)
                if m_inst:
                    tasks_by_file[m_inst.group("file")].append({
                        "kind": "instance_reducible",
                        "line": int(m_inst.group("line")),
                        "name": m_inst.group("name")
                    })
                    continue

            # 2. DefProp
            if not args.no_def_prop:
                m_def = DEF_PROP_REGEX.search(clean)
                if m_def:
                    tasks_by_file[m_def.group("file")].append({
                        "kind": "def_prop",
                        "line": int(m_def.group("line")),
                        "name": m_def.group("name")
                    })
                    continue

            # 3. Unreachable tactic
            if not args.no_unreachable:
                m_unr = UNREACHABLE_TAC_REGEX.search(clean)
                if m_unr:
                    tasks_by_file[m_unr.group("file")].append({
                        "kind": "unreachable_tac",
                        "line": int(m_unr.group("line")),
                        "col": int(m_unr.group("col"))
                    })
                    continue

            # 4. Deprecations
            m_depr = DEPR_REGEX.search(clean)
            if m_depr:
                tasks_by_file[m_depr.group("file")].append({
                    "kind": "ident_replace",
                    "line": int(m_depr.group("line")),
                    "col": int(m_depr.group("col")),
                    "old": m_depr.group("old"),
                    "new": m_depr.group("new_b") or m_depr.group("new_s") or m_depr.group("new_raw")
                })
                continue

            # 5. Unused variables ([apply] _var)
            if not args.no_unused_vars:
                m_var = UNUSED_VAR_START.search(clean)
                if m_var:
                    pending_unused = {
                        "file": m_var.group("file"),
                        "line": int(m_var.group("line")),
                        "col": int(m_var.group("col")),
                        "var": m_var.group("var")
                    }
                    continue

                if pending_unused:
                    m_apply = APPLY_ACTION_REGEX.search(clean)
                    if m_apply:
                        tasks_by_file[pending_unused["file"]].append({
                            "kind": "ident_replace",
                            "line": pending_unused["line"],
                            "col": pending_unused["col"],
                            "old": pending_unused["var"],
                            "new": m_apply.group("new_val")
                        })
                        pending_unused = None
                        continue
                    elif clean and not clean.startswith("Hint:") and not clean.startswith("Alternatively"):
                        pending_unused = None
    finally:
        if args.log_file:
            in_stream.close()

    if not tasks_by_file:
        print("\n[INFO] No actionable suggestions found.", file=sys.stderr)
        return

    total_files = 0
    total_actions = 0

    for file_path in sorted(tasks_by_file.keys()):
        if not os.path.isfile(file_path):
            print(f"[SKIP] File not found: {file_path}", file=sys.stderr)
            continue

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except OSError as e:
            print(f"[ERROR] Could not read {file_path}: {e}", file=sys.stderr)
            continue

        file_changed = False
        reports = []

        # Process all tasks strictly in DESCENDING line order (bottom-to-top)
        # This guarantees line insertions/deletions do not affect earlier line numbers
        sorted_tasks = sorted(tasks_by_file[file_path], key=lambda t: t["line"], reverse=True)

        # Merge multiple identifier replacements on the same line
        grouped_tasks = []
        ident_accum = defaultdict(list)
        for t in sorted_tasks:
            if t["kind"] == "ident_replace":
                ident_accum[t["line"]].append(t)
            else:
                grouped_tasks.append(t)

        for l_num, idents in ident_accum.items():
            grouped_tasks.append({
                "kind": "ident_replace_group",
                "line": l_num,
                "replacements": idents
            })

        grouped_tasks.sort(key=lambda t: t["line"], reverse=True)

        for task in grouped_tasks:
            kind = task["kind"]
            l_num = task["line"]
            idx = l_num - 1

            if kind == "instance_reducible":
                ok, act_idx, attr_line = fix_instance_reducible(lines, idx, task["name"])
                if ok:
                    file_changed = True
                    total_actions += 1
                    reports.append((l_num, "", attr_line.strip(), f"added @[instance_reducible] before `{task['name']}`"))

            elif kind == "def_prop":
                ok, act_idx, orig_l, new_l = fix_def_prop(lines, idx, task["name"])
                if ok:
                    file_changed = True
                    total_actions += 1
                    reports.append((act_idx + 1, orig_l.strip(), new_l.strip(), f"`def {task['name']}` -> `theorem`"))

            elif kind == "unreachable_tac":
                if 0 <= idx < len(lines):
                    orig_l = lines[idx]
                    new_l, ok = fix_unreachable_tactic(orig_l, task["col"], args.delete_unreachable)
                    if ok and orig_l != new_l:
                        lines[idx] = new_l
                        file_changed = True
                        total_actions += 1
                        desc = "deleted dead tactic" if args.delete_unreachable else "commented out dead tactic"
                        reports.append((l_num, orig_l.strip(), new_l.strip(), desc))

            elif kind == "ident_replace_group":
                if 0 <= idx < len(lines):
                    orig_l = lines[idx]
                    new_l, applied = replace_ident_on_line(orig_l, task["replacements"])
                    if orig_l != new_l:
                        lines[idx] = new_l
                        file_changed = True
                        total_actions += len(applied)
                        desc = ", ".join(f"`{a['old']}` -> `{a['new']}`" for a in applied)
                        reports.append((l_num, orig_l.strip(), new_l.strip(), desc))

        if file_changed:
            total_files += 1
            tag = "[DRY-RUN]" if args.dry_run else "[UPDATED]"
            print(f"\n{tag} {file_path}")
            # Display reports in ascending order for readability
            for l_num, old_l, new_l, desc in reversed(reports):
                print(f"  Line {l_num}: {desc}")
                if args.dry_run:
                    if old_l:
                        print(f"    - {old_l}")
                    print(f"    + {new_l}")

            if not args.dry_run:
                try:
                    final_lines = [l for l in lines if l != ""]
                    with open(file_path, "w", encoding="utf-8") as f:
                        f.writelines(final_lines)
                except OSError as e:
                    print(f"[ERROR] Could not write {file_path}: {e}", file=sys.stderr)

    print(f"\nSummary: {total_actions} change(s) across {total_files} file(s).")


if __name__ == "__main__":
    main()
