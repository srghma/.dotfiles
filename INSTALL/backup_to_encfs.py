#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import shutil

ENCFS = Path("/home/srghma/Encfs/Private")
TARGET_PATHS = (
    Path("/home/srghma/.config/google-chrome"),
    Path("/home/srghma/.config/google-chrome-beta-for-srghma-chinese"),
    Path("/home/srghma/projects/nuuz"),
    Path("/home/srghma/projects/vd-rails"),
    Path("/home/srghma/projects/zsh-nordicres"),
    Path("/home/srghma/.ssh"),
    Path("/home/srghma/.aws"),
    Path("/home/srghma/.docker"),
    Path("/home/srghma/.gdfuse"),
)


def backup_path(src: Path) -> str:
    if not src.exists():
        return f"[SKIP] Does not exist: {src}"
    dst = ENCFS / src.name
    shutil.move(str(src), str(dst))
    return f"[MOVED] {src} -> {dst}"


if __name__ == "__main__":
    (lambda: tuple(
        print(msg)
        for msg in ThreadPoolExecutor().map(backup_path, TARGET_PATHS)
    ))()
