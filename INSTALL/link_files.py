#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

import argparse
import os
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from enum import Enum, auto
from pathlib import Path
from typing import Optional, Tuple

from config import DOTFILES, HOME

# ---------------------------------------------------------------------------
# Colors & Formatting
# ---------------------------------------------------------------------------
USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    RED = "\033[31m"
    DIM = "\033[2m"


def colorize(text: str, color_code: str) -> str:
    return f"{color_code}{text}{Colors.RESET}" if USE_COLOR else text


def format_path(path: Path) -> str:
    """Format path with ~ shorthand for HOME."""
    try:
        return f"~/{path.relative_to(HOME)}"
    except ValueError:
        return str(path)


# ---------------------------------------------------------------------------
# Status & Results
# ---------------------------------------------------------------------------
class Status(Enum):
    LINKED = auto()
    SAME = auto()
    UPDATED = auto()
    SKIPPED = auto()
    ERROR = auto()


STATUS_META = {
    Status.LINKED: {"label": "LINKED", "emoji": "🔗", "color": Colors.GREEN},
    Status.SAME: {"label": "SAME", "emoji": "⏭️ ", "color": Colors.CYAN},
    Status.UPDATED: {"label": "UPDATED", "emoji": "🔄", "color": Colors.MAGENTA},
    Status.SKIPPED: {"label": "SKIPPED", "emoji": "⚠️ ", "color": Colors.YELLOW},
    Status.ERROR: {"label": "ERROR", "emoji": "❌", "color": Colors.RED},
}


@dataclass
class LinkResult:
    status: Status
    message: str


# ---------------------------------------------------------------------------
# Configuration mappings
# ---------------------------------------------------------------------------
VSCODE_USER_DIRS = (
    ".config/Code/User",
    ".config/Code - Insiders/User",
    ".config/Code - OSS/User",
    ".config/VSCodium/User",
    ".config/Cursor/User",
    ".config/Windsurf/User",
    ".antigravity-ide/User",
    ".antigravity/User",
    ".config/Antigravity IDE/User",
)

VSCODE_LINKS = tuple(
    (f"{d}/{target}", f"Code/{target}")
    for d in VSCODE_USER_DIRS
    for target in (
        "settings.json",
        # "extensions.json",
        "snippets"
    )
)

INHOME_INDOTFILES: Tuple[Tuple[str, str], ...] = (
    # (".zshrc", "zshrc"),
    # (".tmux.conf", "tmux.conf"),
    (".i3/config", "i3/config"),
    # (".config/joshuto", "joshuto"),
    # (".config/ranger/commands.py", "ranger/commands.py"),
    # (".config/ranger/rc.conf", "ranger/rc.conf"),
    # (".config/ranger/scope.sh", "ranger/scope.sh"),
    (".stack/config.yaml", "stack-global.yaml"),
    (".gitconfig", "gitconfig"),
    (".config/git/ignore", "gitignore_global"),
    (".ctags", "ctags"),
    (".ncmpcpp/bindings", "ncmpcpp_bindings"),
    # (".config/kitty", "kitty"),
    (".commitlintrc.yml", "commitlintrc.yml"),
    (".local/share/applications/mimeapps.list", "mimeapps.list"),
    (".config/mimeapps.list", "mimeapps.list"),
    (".Xresources", "Xresources"),
    (".Xresources.d", "Xresources.d"),
    (".config/nvim", "nvim"),
    (".cabal/config", "cabal_config"),
    (".gnupg/gpg-agent.conf", "gpg-agent.conf"),
    # (".config/kak", "kak"),
    (".config/doom", "doom"),
    (".config/rofi", "rofi"),
    (".config/nushell", "nushell"),
    # Nushell vendor autoload directory ($nu.data-dir/vendor/autoload)
    (".local/share/nushell/vendor/autoload", "nushell/vendor/autoload"),
    (".config/starship.toml", "starship.toml"),
    (".config/yazi", "yazi"),
    (".config/wezterm/wezterm.lua", "wezterm.lua"),
    (".config/flameshot/flameshot.ini", "flameshot.ini"),
    # (".bunfig.toml", ".bunfig.toml"),
) + VSCODE_LINKS


# ---------------------------------------------------------------------------
# Link Action
# ---------------------------------------------------------------------------
def link_pair(pair: Tuple[str, str], force: bool = False, dry_run: bool = False) -> LinkResult:
    inhome, indotfiles = pair
    dst = HOME / inhome
    src = DOTFILES / indotfiles

    dst_str = format_path(dst)
    src_str = format_path(src)

    # 1. Source does not exist in dotfiles
    if not src.exists():
        return LinkResult(Status.SKIPPED, f"Source does not exist: {src_str}")

    # 2. Check if destination is already a symlink pointing to source
    if dst.is_symlink():
        try:
            if dst.resolve() == src.resolve():
                return LinkResult(Status.SAME, f"{dst_str} -> {src_str}")
        except (OSError, RuntimeError):
            pass

    # 3. Handle conflict if dst is a real file or directory (NOT a symlink)
    if dst.exists() and not dst.is_symlink():
        kind = "directory" if dst.is_dir() else "regular file"
        if not force:
            return LinkResult(
                Status.ERROR,
                f"Existing {kind} already exists at {dst_str} (not a symlink). Use --force to replace.",
            )

        # Forced removal
        if not dry_run:
            try:
                if dst.is_dir():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
            except OSError as err:
                return LinkResult(Status.ERROR, f"Failed removing existing {kind} {dst_str}: {err}")

    # 4. If destination was an outdated / broken symlink, remove it
    was_symlink = dst.is_symlink()
    if was_symlink and not dry_run:
        try:
            dst.unlink()
        except OSError as err:
            return LinkResult(Status.ERROR, f"Failed removing stale symlink {dst_str}: {err}")

    # 5. Create symlink
    if not dry_run:
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.symlink_to(src)
        except OSError as err:
            return LinkResult(Status.ERROR, f"Failed linking {dst_str} -> {src_str}: {err}")

    prefix = "[DRY-RUN] " if dry_run else ""
    if was_symlink:
        return LinkResult(Status.UPDATED, f"{prefix}{dst_str} -> {src_str}")
    return LinkResult(Status.LINKED, f"{prefix}{dst_str} -> {src_str}")


# ---------------------------------------------------------------------------
# Runner & CLI
# ---------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Symlink dotfiles safely to HOME.")
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Force overwrite existing real files or directories",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="Preview changes without writing any links to disk",
    )
    parser.add_argument(
        "-j",
        "--jobs",
        type=int,
        default=4,
        help="Number of parallel worker threads (default: 4)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    print(colorize(f"==> Linking dotfiles from {format_path(DOTFILES)} to {format_path(HOME)}...", Colors.BOLD))
    if args.dry_run:
        print(colorize("    [DRY RUN MODE ENABLED - No changes will be applied]", Colors.YELLOW))

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        results = list(
            executor.map(
                lambda pair: link_pair(pair, force=args.force, dry_run=args.dry_run),
                INHOME_INDOTFILES,
            )
        )

    # Print results
    counts = {s: 0 for s in Status}
    for res in results:
        counts[res.status] += 1
        meta = STATUS_META[res.status]
        badge = colorize(f"[{meta['label']:<7}]", meta["color"])
        print(f"{meta['emoji']} {badge} {res.message}")

    # Print summary
    print("\n" + colorize("==> Summary:", Colors.BOLD))
    print(
        f"  Total: {len(results)} | "
        f"{colorize(f'Linked: {counts[Status.LINKED]}', Colors.GREEN)} | "
        f"{colorize(f'Same: {counts[Status.SAME]}', Colors.CYAN)} | "
        f"{colorize(f'Updated: {counts[Status.UPDATED]}', Colors.MAGENTA)} | "
        f"{colorize(f'Skipped: {counts[Status.SKIPPED]}', Colors.YELLOW)} | "
        f"{colorize(f'Errors: {counts[Status.ERROR]}', Colors.RED)}"
    )

    # Return error code if conflicts were encountered
    return 1 if counts[Status.ERROR] > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
