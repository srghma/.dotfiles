# like
#
# gc -m "my commit" = git commit -m "my commit"
#
# but
# will prepent [only-deploy] to message
#
# gco -m "my commit" = git commit -m "my commit [only-deploy]"
# gco -m "my commit" --author asdf = git commit -m "my commit [only-deploy]" --author asdf
# gco --author asdf -m "my commit" = git commit --author asdf -m "my commit [only-deploy]"

gcod() {
  local args=()
  local msg=""
  local found_message_flag=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--message)
        found_message_flag=1
        msg="$2 [only-deploy]"
        args+=("-m" "$msg")
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  if [[ $found_message_flag -eq 0 ]]; then
    echo "Error: Commit message not provided. Use -m or --message."
    return 1
  fi

  git commit -v "${args[@]}"
}

# like
#
# gc! -m "my commit" = git commit --amend -m "my commit"
#
# but
# will prepent [only-deploy] to message
#
# gco! -m "my commit" = git commit --amend -m "my commit [only-deploy]"
# gco! -m "my commit" --author asdf = git commit --amend -m "my commit [only-deploy]" --author asdf
# gco! --author asdf -m "my commit" = git commit --amend --author asdf -m "my commit [only-deploy]"

gc!od() {
  local msg=""
  local args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--message)
        msg="$2 [only-deploy]"
        shift 2
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  if [ -z "$msg" ]; then
    echo "Error: Commit message not provided. Use -m or --message."
    return 1
  fi

  git commit -v --amend "${args[@]}" -m "$msg"
}
