#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

import argparse
import shutil
import sys
from pathlib import Path

from lib.config import DOTFILES
from lib.colors import Colors, colorize
from link_files_config import INHOME_INDOTFILES, Action


def copy_shared_files(target_home: Path) -> int:
    print(colorize(f"==> Copying 🤝 safe dotfiles to {target_home}...", Colors.BOLD))
    target_home.mkdir(parents=True, exist_ok=True)
    copied = 0
    errors = 0

    for action, inhome, indotfiles in INHOME_INDOTFILES:
        if action is not Action.LINK_SRGHMA_AND_TESTUSER:
            continue

        src = DOTFILES / indotfiles
        dst = target_home / inhome

        if not src.exists():
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            if src.is_dir():
                if dst.exists():
                    shutil.rmtree(dst)
                shutil.copytree(src, dst)
            else:
                # Safely unlink existing file or broken symlink (no chmod needed)
                if dst.is_symlink() or dst.exists():
                    dst.unlink()
                shutil.copy2(src, dst)
            print(f"🤝 {colorize('[COPIED]', Colors.GREEN)} {inhome} <- {indotfiles}")
            copied += 1
        except Exception as err:
            print(f"❌ {colorize('[FAILED]', Colors.RED)} {inhome}: {err}")
            errors += 1

    print(colorize(f"==> Done: {copied} copied, {errors} errors.", Colors.BOLD))
    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copy 🤝 safe dotfiles to testuser home directory."
    )
    parser.add_argument(
        "target",
        type=Path,
        help="Target home directory",
    )
    args = parser.parse_args()
    return copy_shared_files(args.target)


if __name__ == "__main__":
    sys.exit(main())
