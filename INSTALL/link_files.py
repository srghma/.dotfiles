#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

import argparse
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Tuple, TypeAlias

from lib.config import DOTFILES, HOME
from lib.colors import Colors, colorize
from link_files_config import INHOME_INDOTFILES, Action

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------


def format_path(path: Path) -> str:
    """Format path with ~ shorthand for HOME."""
    try:
        return f"~/{path.relative_to(HOME)}"
    except ValueError:
        return str(path)


def same_target(dst: Path, src: Path) -> bool:
    try:
        return dst.resolve(strict=False) == src.resolve(strict=False)
    except (OSError, RuntimeError):
        return False


# ---------------------------------------------------------------------------
# Link Results
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class Linked:
    src: Path
    dst: Path


@dataclass(frozen=True)
class AlreadyLinked:
    src: Path
    dst: Path


@dataclass(frozen=True)
class Updated:
    src: Path
    dst: Path


@dataclass(frozen=True)
class SourceMissing:
    src: Path
    dst: Path


@dataclass(frozen=True)
class ExistingDestination:
    dst: Path
    kind: str


@dataclass(frozen=True)
class DisabledLinkRemoved:
    src: Path
    dst: Path


@dataclass(frozen=True)
class DisabledLinkNotRemoved:
    src: Path
    dst: Path
    reason: str


@dataclass(frozen=True)
class DisabledLinkAlreadyAbsent:
    src: Path
    dst: Path


@dataclass(frozen=True)
class LinkError:
    src: Path
    dst: Path
    reason: str


LinkResult: TypeAlias = (
    Linked
    | AlreadyLinked
    | Updated
    | SourceMissing
    | ExistingDestination
    | DisabledLinkRemoved
    | DisabledLinkNotRemoved
    | DisabledLinkAlreadyAbsent
    | LinkError
)


def format_link_result(result: LinkResult) -> str:
    match result:
        case Linked(src, dst):
            return f"{format_path(dst)} -> {format_path(src)}"

        case AlreadyLinked(src, dst):
            return f"{format_path(dst)} -> {format_path(src)}"

        case Updated(src, dst):
            return f"{format_path(dst)} -> {format_path(src)}"

        case SourceMissing(src, dst):
            return (
                f"Source does not exist: {format_path(src)} "
                f"(destination: {format_path(dst)})"
            )

        case ExistingDestination(dst, kind):
            return f"Existing {kind}: {format_path(dst)}"

        case DisabledLinkRemoved(src, dst):
            return (
                f"Removed obsolete symlink: "
                f"{format_path(dst)} -> {format_path(src)}"
            )

        case DisabledLinkNotRemoved(src, dst, reason):
            return (
                f"Not removed: {format_path(dst)} "
                f"(expected {format_path(src)}): {reason}"
            )

        case DisabledLinkAlreadyAbsent(src, dst):
            return (
                f"Disabled mapping already absent: "
                f"{format_path(dst)} "
                f"(expected link to {format_path(src)})"
            )

        case LinkError(src, dst, reason):
            return (
                f"Error: {format_path(dst)} -> "
                f"{format_path(src)}: {reason}"
            )

        case _:
            raise AssertionError(f"Unhandled LinkResult: {result!r}")


# ---------------------------------------------------------------------------
# Link Action
# ---------------------------------------------------------------------------
def link_entry(
    entry: Tuple[Action, str, str],
    force: bool = False,
    dry_run: bool = False,
) -> LinkResult:
    action, inhome, indotfiles = entry

    dst = HOME / inhome
    src = DOTFILES / indotfiles

    # 1. Disabled (Unlink) mappings: remove only the expected symlink.
    if action is Action.UNLINK:
        if not dst.is_symlink():
            if dst.exists():
                kind = "directory" if dst.is_dir() else "regular file"
                return DisabledLinkNotRemoved(
                    src, dst, f"destination is a {kind}, not a symlink"
                )

            return DisabledLinkAlreadyAbsent(src, dst)

        if not same_target(dst, src):
            try:
                actual = dst.resolve(strict=False)
            except (OSError, RuntimeError):
                actual = None

            return DisabledLinkNotRemoved(
                src,
                dst,
                f"symlink points elsewhere ({actual})",
            )

        if dry_run:
            return DisabledLinkRemoved(src, dst)

        try:
            dst.unlink()
            return DisabledLinkRemoved(src, dst)
        except OSError as err:
            return LinkError(src, dst, str(err))

    # 2. Normal mappings: source must exist.
    if not src.exists():
        return SourceMissing(src, dst)

    # 3. Already linked correctly.
    if dst.is_symlink() and same_target(dst, src):
        return AlreadyLinked(src, dst)

    # 4. Existing real file or directory.
    if dst.exists() and not dst.is_symlink():
        kind = "directory" if dst.is_dir() else "regular file"

        if not force:
            return ExistingDestination(dst, kind)

        if not dry_run:
            try:
                if dst.is_dir():
                    shutil.rmtree(dst)
                else:
                    dst.unlink()
            except OSError as err:
                return LinkError(src, dst, str(err))

    # 5. Remove outdated or broken symlink.
    was_symlink = dst.is_symlink()

    if was_symlink and not dry_run:
        try:
            dst.unlink()
        except OSError as err:
            return LinkError(src, dst, str(err))

    # 6. Create symlink.
    if not dry_run:
        try:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.symlink_to(src)
        except OSError as err:
            return LinkError(src, dst, str(err))

    return Updated(src, dst) if was_symlink else Linked(src, dst)


# ---------------------------------------------------------------------------
# Result Display
# ---------------------------------------------------------------------------
RESULT_META = {
    Linked: ("LINKED", "🔗", Colors.GREEN),
    AlreadyLinked: ("SAME", "⏭️ ", Colors.CYAN),
    Updated: ("UPDATED", "🔄", Colors.MAGENTA),
    SourceMissing: ("MISSING SOURCE", "⚠️ ", Colors.YELLOW),
    ExistingDestination: ("CONFLICT", "⚠️ ", Colors.YELLOW),
    DisabledLinkRemoved: ("REMOVED", "🗑️ ", Colors.GREEN),
    DisabledLinkNotRemoved: ("NOT REMOVED", "⚠️ ", Colors.YELLOW),
    DisabledLinkAlreadyAbsent: ("ABSENT", "⏭️ ", Colors.DIM),
    LinkError: ("ERROR", "❌", Colors.RED),
}

DRY_RUN_LABELS = {
    Linked: "WOULD LINK",
    Updated: "WOULD UPDATE",
    DisabledLinkRemoved: "WOULD REMOVE",
}


def print_result(result: LinkResult, dry_run: bool = False) -> None:
    try:
        label, emoji, color = RESULT_META[type(result)]
    except KeyError:
        raise AssertionError(
            f"Missing display metadata for {type(result).__name__}"
        ) from None

    if dry_run and type(result) in DRY_RUN_LABELS:
        label = DRY_RUN_LABELS[type(result)]

    badge = colorize(f"[{label:<16}]", color)
    print(f"{emoji} {badge} {format_link_result(result)}")


# ---------------------------------------------------------------------------
# Runner & CLI
# ---------------------------------------------------------------------------
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Symlink dotfiles safely to HOME."
    )
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

    if args.jobs < 1:
        print("Error: --jobs must be at least 1", file=sys.stderr)
        return 2

    print(
        colorize(
            f"==> Linking dotfiles from {format_path(DOTFILES)} "
            f"to {format_path(HOME)}...",
            Colors.BOLD,
        )
    )

    if args.dry_run:
        print(
            colorize(
                "    [DRY RUN MODE ENABLED - No changes will be applied]",
                Colors.YELLOW,
            )
        )

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        results = list(
            executor.map(
                lambda entry: link_entry(
                    entry,
                    force=args.force,
                    dry_run=args.dry_run,
                ),
                INHOME_INDOTFILES,
            )
        )

    for result in results:
        print_result(result, dry_run=args.dry_run)

    counts = {
        cls: sum(isinstance(result, cls) for result in results)
        for cls in RESULT_META
    }

    linked = counts[Linked]
    updated = counts[Updated]
    removed = counts[DisabledLinkRemoved]

    print("\n" + colorize("==> Summary", Colors.BOLD))

    print(colorize("  Changes", Colors.BOLD))
    print(
        f"    {'Would link' if args.dry_run else 'Linked':<20} {linked:>4}\n"
        f"    {'Would update' if args.dry_run else 'Updated':<20} {updated:>4}\n"
        f"    {'Would remove' if args.dry_run else 'Removed':<20} {removed:>4}"
    )

    print("\n" + colorize("  Unchanged", Colors.BOLD))
    print(
        f"    {'Already linked':<20} {counts[AlreadyLinked]:>4}\n"
        f"    {'Already absent':<20} {counts[DisabledLinkAlreadyAbsent]:>4}"
    )

    print("\n" + colorize("  Problems", Colors.BOLD))
    print(
        f"    {'Missing sources':<20} {counts[SourceMissing]:>4}\n"
        f"    {'Conflicts':<20} {counts[ExistingDestination]:>4}\n"
        f"    {'Not removed':<20} {counts[DisabledLinkNotRemoved]:>4}\n"
        f"    {'Errors':<20} {counts[LinkError]:>4}"
    )

    print(
        "\n"
        + colorize(
            f"  Total: {len(results)}",
            Colors.BOLD,
        )
    )

    return 1 if counts[LinkError] or counts[ExistingDestination] else 0


if __name__ == "__main__":
    sys.exit(main())
