aristotle_pull() {
  local target="${1:?Usage: aristotle_pull <project_id_or_url>}"
  local api_key="${ARISTOTLE_API_KEY:-$ARISTOTLE_API_KEY__SRGHMA_GMAIL_COM}"

  if [[ -z "$api_key" ]]; then
    echo "Error: ARISTOTLE_API_KEY is not set." >&2
    return 1
  fi

  # Extract UUID if full URL was provided
  local project_id
  if [[ "$target" =~ 'projects/([a-f0-9-]{36})' ]]; then
    project_id="${match[1]}"
  else
    project_id="$target"
  fi

  local tmp
  tmp=$(mktemp -d) || return 1
  trap "rm -rf ${(q)tmp}" EXIT INT TERM

  echo "==> Downloading Aristotle project: $project_id ..."
  ARISTOTLE_API_KEY="$api_key" aristotle download --destination "$tmp/archive" "$project_id" || return 1

  echo "==> Extracting LeanScript and TyTests ..."
  mkdir -p "$tmp/extracted"
  tar -xzf "$tmp/archive" --strip-components=1 -C "$tmp/extracted"

  rsync -av --delete "$tmp/extracted/LeanScript/" ./LeanScript/
  rsync -av --delete "$tmp/extracted/TyTests/" ./TyTests/
  rsync -av --delete "$tmp/extracted/NonEmpty/" ./NonEmpty/
  rsync -av --delete "$tmp/lakefile.toml" ./lakefile.toml

  echo "==> Done!"
}
