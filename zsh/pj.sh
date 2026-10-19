function pj() {
  local -a cmd=(cd)
  local target

  if [[ "$1" == "open" ]]; then
    shift
    target="$*"
    cmd=("${(s: :)EDITOR}")
  else
    target="$*"
  fi

  # Prevent jumping to project root if invoked without arguments
  if [[ -z "$target" ]]; then
    echo "Usage: pj [open] <project-or-subfolder>" >&2
    return 1
  fi

  for project in "${PROJECT_PATHS[@]}"; do
    if [[ -d "$project/$target" ]]; then
      "${cmd[@]}" "$project/$target"
      return 0
    fi
  done

  echo "No such project or directory: $target" >&2
  return 1
}

alias pjo="pj open"

function _pj() {
  if [[ $service == "pj" ]] && (( CURRENT == 2 )); then
    local -a subcmds
    subcmds=('open:open project in $EDITOR')
    _describe -t commands 'command' subcmds
  fi

  _path_files -/ -W PROJECT_PATHS
}

compdef _pj pj
compdef _pj pjo
