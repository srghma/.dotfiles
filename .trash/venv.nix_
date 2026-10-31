#!/usr/bin/env -S bash -c 'nix-shell --pure $0 -A env'

# Usage:
# 1. run directly to enter bash (inside venv): `./venv-py37.nix`
# 2. build a standalone executable: `nix bundle -f ./venv-py37.nix`  #this not works yet since it cause nested `unshare -U` call
# 3. run bash with extra arguments: `nix run -f ./venv-py37.nix '' -- -c 'python --version'`
# More:
# 1. commit id of nixpkgs can be found here: https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=python3

let
  makeOverridable = f: f { } // { override = y: makeOverridable (x: f (x // y)); };
in
makeOverridable ()
