# Convert SSH Git URL to HTTPS GitLab/GitHub URL
git_ssh_to_https_url() {
  local ssh_url="$1"

  # Remove possible prefixes/suffixes
  local host_path="${ssh_url#ssh://git@}"     # remove ssh://git@
  host_path="${host_path#git@}"               # remove git@ (for git@host:path.git form)
  host_path="${host_path%.git}"               # remove .git
  host_path="${host_path/:/\/}"               # convert : to / → git@host:org/repo → host/org/repo

  local host_port="${host_path%%/*}"          # extract host (with port if any)
  local path="${host_path#*/}"                # extract path

  local host="${host_port%%:*}"               # remove port if any

  echo "https://${host}/${path}"
}

function gpo-open() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local url=""

  if git remote get-url upstream &>/dev/null; then
    url=$(git remote get-url upstream)
  else
    url=$(git remote get-url origin)
  fi

  echo "branch: $branch"
  echo "git url: $url"

  local https_url=$(git_ssh_to_https_url "$url")
  local final_url="${https_url}/-/merge_requests/new?merge_request%5Bsource_branch%5D=${branch}"

  echo "Opening: $final_url"
  /run/current-system/sw/bin/xdg-open "$final_url"
}
