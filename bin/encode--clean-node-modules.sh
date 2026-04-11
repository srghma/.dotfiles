#!/usr/bin/env bash
set -euo pipefail
# Remove all node_modules directories inside paths listed in ~/.config/encode-list.txt

set -euo pipefail

LIST="${HOME}/.config/encode-list.txt"

if [[ ! -f "$LIST" ]]; then
  echo "❌ encode-list.txt not found at $LIST"
  exit 1
fi

echo "🧹 Cleaning node_modules from paths listed in $LIST"

while IFS= read -r raw_path; do
  [[ -z "$raw_path" ]] && continue

  # Expand ~ and environment variables manually
  eval "path=${raw_path}"

  if [[ ! -d "$path" ]]; then
    echo "⚠️  Skipping (not a directory): $raw_path"
    continue
  fi

  echo "📂 Processing: $path"
  find "$path" -type d -name "node_modules" -prune -print -exec rm -rf {} +
done < "$LIST"

echo "✅ Done — all node_modules removed from listed directories."
