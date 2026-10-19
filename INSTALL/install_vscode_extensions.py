#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
from concurrent.futures import ThreadPoolExecutor
import subprocess

EXTENSIONS = (
    "alanz.vscode-hie-server",
    "bbenoist.nix",
    "castwide.solargraph",
    "eamodio.gitlens",
    "eg2.tslint",
    "eg2.vscode-npm-script",
    "felipecaputo.git-project-manager",
    "justusadam.language-haskell",
    "karunamurti.haml",
    "Kasik96.swift",
    "ms-python.python",
    "PeterJausovec.vscode-docker",
    "rebornix.ruby",
    "sianglim.slim",
)


def install_extension(ext: str) -> str:
    res = subprocess.run(
        ["code", "--install-extension", ext],
        capture_output=True,
        text=True,
    )
    status = "OK" if res.returncode == 0 else f"ERR: {res.stderr.strip()}"
    return f"[{status}] {ext}"


if __name__ == "__main__":
    (lambda: tuple(
        print(msg)
        for msg in ThreadPoolExecutor(max_workers=4).map(install_extension, EXTENSIONS)
    ))()
