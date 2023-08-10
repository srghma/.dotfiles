#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git

SCRIPT_DIR=$(dirname "$(readlink -f "$BASH_SOURCE")")
new_revision=$(nix-prefetch-git https://github.com/srghma/nixpkgs --rev 36c772b5f3b79c6831427edb3bc4e61c72316bec --no-deepClone)
echo "$new_revision" > "$SCRIPT_DIR/revision.json"
