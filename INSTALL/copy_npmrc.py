#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

# XXX: copy, instead of link, because npm adds secret access_token to it
import shutil
from config import DOTFILES, HOME

if __name__ == "__main__":
    (lambda: shutil.copy2(DOTFILES / "npmrc", HOME / ".npmrc"))()
