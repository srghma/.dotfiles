rgr() {
  # 1. Enforce minimum argument count
  if [[ $# -lt 3 ]]; then
    echo "Usage: rgr <search_pattern> <replacement_string> <file_paths...>" >&2
    return 1
  fi

  local search_str="$1"
  local replace_raw="$2"
  shift 2 # Remove the first two arguments, leaving only the file paths

  # 2. Expand escape sequences (like \n, \t, etc.) in the replacement string
  # This converts the literal characters "\n" into a real newline character
  local replace_str
  printf -v replace_str "%b" "$replace_raw"

  # 3. Find files containing the string and replace it
  # We keep -F on both to ensure the search_pattern is treated as a literal string
  # sd handles actual newline bytes in the replacement argument correctly with -F
  rg -lF "$search_str" "$@" | xargs -r sd -F "$search_str" "$replace_str"
}

rgd() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: rgd <search_pattern> <file_paths...>" >&2
    return 1
  fi

  local search_str="$1"
  shift 1

  # Filter out empty arguments from the remaining paths
  local paths=()
  for arg in "$@"; do
    [[ -n "$arg" ]] && paths+=("$arg")
  done

  # If no paths remain after filtering
  if [[ ${#paths[@]} -eq 0 ]]; then
    echo "Error: No valid file paths provided." >&2
    return 1
  fi

  local escaped_search=$(printf '%s\n' "$search_str" | sed 's/[^^]/[&]/g; s/\^/\\^/g')

  # Use "${paths[@]}" instead of "$@"
  rg -lF "$search_str" "${paths[@]}" | xargs -r sed -i "/$escaped_search/d"
}
