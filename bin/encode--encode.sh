#!/usr/bin/env bash
# encode--encode.sh
#
# Encrypts directories listed in ~/.config/encode-list.txt using agevault.
#
# Prerequisites:
#   1. agevault installed (https://github.com/ndavd/agevault)
#   2. Create ~/.config/encode-list.txt with one directory path per line
#
# The script will:
#   - Read directories from ~/.config/encode-list.txt
#   - Lock (encrypt) each directory using agevault
#   - Each directory gets its own passphrase-protected identity file
#   - Identity files are stored next to the directories (as .age*.key.age files)
#
# Usage:
#   ./bin/encode--encode.sh
#
# Note: You'll be prompted for a passphrase for each directory if it's the first time
set -euo pipefail

LIST="${HOME}/.config/encode-list.txt"

if ! command -v agevault &> /dev/null; then
  echo "❌ agevault not found. Please install it:"
  echo "   https://github.com/ndavd/agevault"
  echo ""
  echo "   Or with go: go install github.com/ndavd/agevault@latest"
  exit 1
fi

if [[ ! -f "$LIST" ]]; then
  echo "❌ encode-list.txt not found at $LIST"
  echo ""
  echo "Create it with directories to encrypt, one per line:"
  echo "  echo '~/.ssh' > $LIST"
  echo "  echo '~/.local/share/TelegramDesktop/tdata' >> $LIST"
  exit 1
fi

echo "🔐 Encrypting directories with agevault"
echo ""

SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

# Read all paths into an array first to avoid stdin issues
mapfile -t paths < <(grep -v '^\s*#' "$LIST" | grep -v '^\s*$')

for raw_path in "${paths[@]}"; do
  # Expand ~ and env variables
  eval "path=$raw_path"

  if [[ ! -d "$path" ]]; then
    echo "⚠️  Skipping (not a directory): $path"
    ((SKIP_COUNT++))
    continue
  fi

  # Check if already locked
  if [[ -f "${path}.tar.age" ]]; then
    echo "🔒 Already locked: $path"
    ((SKIP_COUNT++))
    continue
  fi

  name=$(basename "$path")
  parent_dir=$(dirname "$path")

  # Check if identity file exists, if not, generate it
  identity_files=("${parent_dir}"/.age*."${name}".key.age)
  if [[ ! -f "${identity_files[0]}" ]]; then
    echo "🔑 Generating identity file for: $path"

    # Change to parent directory before generating identity
    pushd "$parent_dir" > /dev/null

    if agevault "$path" keygen < /dev/tty; then
      echo "✅ Identity file generated"
    else
      echo "❌ Failed to generate identity file for: $path"
      popd > /dev/null
      ((ERROR_COUNT++))
      continue
    fi

    popd > /dev/null
    echo ""
  fi

  echo "🔒 Locking: $path"

  # Change to parent directory before locking
  pushd "$parent_dir" > /dev/null

  if agevault "$path" lock < /dev/tty; then
    ((SUCCESS_COUNT++))
  else
    echo "❌ Failed to lock: $path"
    ((ERROR_COUNT++))
  fi

  popd > /dev/null
  echo ""
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done!"
echo "   Locked:  $SUCCESS_COUNT"
echo "   Skipped: $SKIP_COUNT"
echo "   Errors:  $ERROR_COUNT"
echo ""
echo "💡 Use encode--decode.sh to unlock directories"
echo "💡 Identity files (.age*.key.age) are stored next to each directory"
