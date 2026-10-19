#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Tuple
from config import DOTFILES, HOME

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
    for target in ("settings.json", "extensions.json", "snippets")
)

INHOME_INDOTFILES: Tuple[Tuple[str, str], ...] = (
    (".zshrc", "zshrc"),
    (".tmux.conf", "tmux.conf"),
    (".i3/config", "i3/config"),
    (".config/joshuto", "joshuto"),
    (".config/ranger/commands.py", "ranger/commands.py"),
    (".config/ranger/rc.conf", "ranger/rc.conf"),
    (".config/ranger/scope.sh", "ranger/scope.sh"),
    (".stack/config.yaml", "stack-global.yaml"),
    (".gitconfig", "gitconfig"),
    (".config/git/ignore", "gitignore_global"),
    (".ctags", "ctags"),
    (".ncmpcpp/bindings", "ncmpcpp_bindings"),
    (".config/kitty", "kitty"),
    (".commitlintrc.yml", "commitlintrc.yml"),
    (".local/share/applications/mimeapps.list", "mimeapps.list"),
    (".config/mimeapps.list", "mimeapps.list"),
    (".Xresources", "Xresources"),
    (".Xresources.d", "Xresources.d"),
    (".config/nvim", "nvim"),
    (".cabal/config", "cabal_config"),
    (".gnupg/gpg-agent.conf", "gpg-agent.conf"),
    (".config/kak", "kak"),
    (".config/doom", "doom"),
    (".config/rofi", "rofi"),
    (".config/nushell", "nushell"),
    (".config/starship.toml", "starship.toml"),
    (".bunfig.toml", ".bunfig.toml"),
) + VSCODE_LINKS


def link_pair(pair: Tuple[str, str]) -> str:
    inhome, indotfiles = pair
    dst = HOME / inhome
    src = DOTFILES / indotfiles

    if not src.exists():
        return f"[SKIP] Source does not exist: {src}"

    dst.parent.mkdir(parents=True, exist_ok=True)

    # Force replace existing regular file or symlink
    if dst.is_symlink() or dst.exists():
        if dst.is_dir() and not dst.is_symlink():
            import shutil
            shutil.rmtree(dst)
        else:
            dst.unlink()

    dst.symlink_to(src)
    return f"[LINKED] {dst} -> {src}"


if __name__ == "__main__":
    (lambda: tuple(
        print(msg)
        for msg in ThreadPoolExecutor().map(link_pair, INHOME_INDOTFILES)
    ))()
