#!/usr/bin/env bash
# Recursively find git repositories and reset them

set -euo pipefail

LIST="${HOME}/.config/encode-list.txt"

if [[ ! -f "$LIST" ]]; then
  echo "❌ encode-list.txt not found at $LIST"
  exit 1
fi

echo "🔍 Searching for git repositories under paths listed in $LIST"

while IFS= read -r raw_path; do
  [[ -z "$raw_path" ]] && continue

  # Expand ~ and environment variables
  eval "path=${raw_path}"

  if [[ ! -d "$path" ]]; then
    echo "⚠️  Skipping (not a directory): $raw_path"
    continue
  fi

  # Find all directories containing a .git folder
  git_dirs=$(find "$path" -type d -name ".git")

  if [[ -z "$git_dirs" ]]; then
    echo "⚠️  No git repositories found under: $path"
    continue
  fi

  while IFS= read -r git_dir; do
    repo_dir=$(dirname "$git_dir")
    echo "📂 Processing git repo: $repo_dir"

    pushd "$repo_dir" > /dev/null
    git reset --hard
    git clean -fdx
    popd > /dev/null
  done <<< "$git_dirs"

done < "$LIST"

echo "✅ Done — all git repositories under listed directories have been reset."
