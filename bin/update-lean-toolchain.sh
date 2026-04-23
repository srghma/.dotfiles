#!/usr/bin/env bash
set -euo pipefail

NEW="${1:-}" # leanprover/lean4:v4.30.0-rc2

if [[ -z "$NEW" ]]; then
  echo "Usage: $0 leanprover/lean4:v4.xx.x"
  exit 1
fi

# taken from `elan toolchain gc --delete`
PROJECTS=(
  "$HOME/projects/lean-pipes/pipes"
  "$HOME/projects/lean-pipes/correctness"
  "$HOME/projects/lean-spec"
  "$HOME/projects/lean-glob"
  "$HOME/projects/lean-spec/.lake/packages/mathlib"
  "$HOME/projects/lean-nonempty"
  "$HOME/projects/mm0/mm0-lean4"
  "$HOME/projects/mm-lean4"
  "$HOME/projects/khmer/lllll"
  "$HOME/projects/aenasverif/aeneas/tests/lean"
  "$HOME/projects/aenasverif/icfp-tutorial"
  "$HOME/projects/aenasverif/aeneas/backends/lean"
  "$HOME/projects/purescript-backend-optimizer"
  "$HOME/projects/import-graph"
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
  if [[ -f "$p/lakefile.lean" || -f "$p/lakefile.toml" ]]; then
    (cd "$p" && lake update) || true
  fi
done

echo
echo "Done. Current elan status:"
elan show
