#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
from pathlib import Path
import os

DOTFILES: Path = Path(__file__).resolve().parent.parent
HOME: Path = Path(os.environ["HOME"])
