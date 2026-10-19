#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
"""Sort JSON files with comments (JSONC), preserving line comments and grouping

commented-out keys next to active keys.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import List, NamedTuple, Sequence, Tuple
import argparse
import re
import sys


class Block(NamedTuple):
    key: str
    lines: Tuple[str, ...]
    is_commented_key: bool


def parse_blocks(inner_lines: Sequence[str]) -> List[Block]:
    """Purely parses lines inside root braces into key/comment blocks."""
    blocks: List[Block] = []
    attached_comments: List[str] = []
    i = 0
    total = len(inner_lines)

    while i < total:
        line = inner_lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        # 1. Commented-out key: // "key.name": value
        commented_key_match = re.match(r'^\s*//\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*:', line)
        if commented_key_match:
            blocks.append(
                Block(
                    key=commented_key_match.group(1),
                    lines=tuple(attached_comments + [line]),
                    is_commented_key=True,
                )
            )
            attached_comments = []
            i += 1
            continue

        # 2. General comment line: // comment or /* comment */
        if stripped.startswith("//") or stripped.startswith("/*"):
            attached_comments.append(line)
            i += 1
            continue

        # 3. Active key: "key.name": value
        active_key_match = re.match(r'^\s*"([^"\\]*(?:\\.[^"\\]*)*)"\s*:', line)
        if active_key_match:
            key_name = active_key_match.group(1)
            block_lines = attached_comments + [line]
            attached_comments = []

            # Balance braces and brackets for multiline values
            brace_count = line.count("{") - line.count("}")
            bracket_count = line.count("[") - line.count("]")

            while (brace_count > 0 or bracket_count > 0) and (i + 1 < total):
                i += 1
                next_line = inner_lines[i]
                brace_count += next_line.count("{") - next_line.count("}")
                bracket_count += next_line.count("[") - next_line.count("]")
                block_lines.append(next_line)

            blocks.append(
                Block(
                    key=key_name,
                    lines=tuple(block_lines),
                    is_commented_key=False,
                )
            )
        else:
            attached_comments.append(line)

        i += 1

    return blocks


def sort_jsonc(src: str, indent: str = "    ") -> str:
    """Sorts top-level keys case-insensitively while preserving comments and

    syntax.
    """
    first_brace = src.find("{")
    last_brace = src.rfind("}")

    if first_brace == -1 or last_brace == -1 or first_brace >= last_brace:
        return src

    prefix = src[:first_brace]
    inner = src[first_brace + 1 : last_brace]
    suffix = src[last_brace + 1 :]

    blocks = parse_blocks(inner.splitlines())
    # Sort case-insensitively; commented-out keys precede active keys with the same name
    sorted_blocks = sorted(blocks, key=lambda b: (b.key.lower(), not b.is_commented_key))

    def format_block(block: Block) -> Tuple[str, ...]:
        formatted = []
        for j, line in enumerate(block.lines):
            is_last = j == len(block.lines) - 1
            s = line.rstrip()
            if is_last and not block.is_commented_key and not s.endswith(","):
                s += ","
            if not s.startswith(indent) and not s.startswith("\t"):
                s = indent + s.lstrip()
            formatted.append(s)
        return tuple(formatted)

    body_lines = [line for b in sorted_blocks for line in format_block(b)]
    return f"{prefix}{{\n" + "\n".join(body_lines) + f"\n}}{suffix}"


def process_file(path: Path, in_place: bool) -> str:
    """Processes a single file; writes in-place or returns formatted output."""
    try:
        content = path.read_text(encoding="utf-8")
        sorted_content = sort_jsonc(content)
        if in_place:
            path.write_text(sorted_content, encoding="utf-8")
            return f"[OK] Sorted in-place: {path}"
        return sorted_content
    except Exception as e:
        return f"[ERROR] Failed {path}: {e}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sort JSON files with comments (JSONC) preserving structure and comments."
    )
    parser.add_argument("files", nargs="*", type=Path, help="Files to sort. Reads stdin if omitted.")
    parser.add_argument(
        "-i",
        "--in-place",
        action="store_true",
        default=True,
        help="Modify files in-place (default: true when files are given).",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print result to stdout instead of in-place editing.",
    )
    return parser


if __name__ == "__main__":
    (lambda args: (
        print(sort_jsonc(sys.stdin.read()))
        if not args.files
        else tuple(
            print(msg)
            for msg in ThreadPoolExecutor().map(
                lambda p: process_file(p, in_place=not args.stdout),
                args.files,
            )
        )
    ))(build_parser().parse_args())
