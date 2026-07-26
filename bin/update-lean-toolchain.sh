#!/usr/bin/env bash
set -euo pipefail

# NEW="${1:-}" # leanprover/lean4:v4.33.0-rc1
NEW="leanprover/lean4:v4.33.0-rc1"

if [[ -z "$NEW" ]]; then
  echo "Usage: $0 leanprover/lean4:v4.xx.x"
  exit 1
fi

# taken from `elan toolchain gc --delete`
PROJECTS=(
 "/home/srghma/projects/LSpec"
 "/home/srghma/projects/PLFaLean"
 "/home/srghma/projects/iris-lean/Iris"
 "/home/srghma/projects/iris-lean/IrisMath"
 "/home/srghma/projects/lean-glob"
 "/home/srghma/projects/lean-nonempty"
 "/home/srghma/projects/lean-rust-parser"
 "/home/srghma/projects/lean-spec"
 "/home/srghma/projects/lean4-unicode-basic/common"
 "/home/srghma/projects/lean4-unicode-basic/docs"
 "/home/srghma/projects/lean4-unicode-basic/lean-scripts"
 "/home/srghma/projects/lean4-unicode-basic/lib"
 "/home/srghma/projects/lean4-unicode-basic/table-generators"
 "/home/srghma/projects/lean4-unicode-basic/tests"
 "/home/srghma/projects/lean4lean"
 "/home/srghma/projects/rc-correctness"
)

echo "Installing toolchain: $NEW"
elan toolchain install "$NEW" || true

for p in "${PROJECTS[@]}"; do
  if [[ ! -d "$p" ]]; then
    echo "Skipping missing: $p"
    continue
  fi

  if [[ ! -f "$p/lean-toolchain" ]]; then
    echo "Skipping (no lean-toolchain): $p"
    continue
  fi

  old="$(cat "$p/lean-toolchain")"

  if [[ "$old" == "$NEW" ]]; then
    echo "Already OK: $p"
    continue
  fi

  echo "Updating: $p"
  echo "  $old  ->  $NEW"
  echo "$NEW" > "$p/lean-toolchain"

  # optional: update lake deps immediately
  # if [[ -f "$p/lakefile.lean" || -f "$p/lakefile.toml" ]]; then
  #   (cd "$p" && lake update) || true
  # fi
done

echo
echo "Done. Current elan status:"
elan show
