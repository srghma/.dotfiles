git-remote-add-or-set-url() {
  local remote_name="$1"
  local url="$2"

  if git remote get-url "$remote_name" &>/dev/null; then
    # Only update if the URL is actually different to keep output clean
    if [ "$(git remote get-url "$remote_name")" != "$url" ]; then
      git remote set-url "$remote_name" "$url"
      echo "Set $remote_name to $url"
    fi
  else
    git remote add "$remote_name" "$url"
    echo "Added $remote_name $url"
  fi
}

git-remote-setup-fork () {
  # 1. Get current authentic GitHub username
  local my_gh_user
  my_gh_user=$(gh api user -q .login)

  if [ -z "$my_gh_user" ]; then
    echo "Error: Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
    return 1
  fi

  # 2. Get the repository name (stripping .git if present)
  local current_origin_url
  current_origin_url=$(git remote get-url origin)
  local repo_name
  repo_name=$(basename "$current_origin_url" .git)

  echo "Detected User: $my_gh_user"
  echo "Detected Repo: $repo_name"

  # 3. Ensure the fork exists on GitHub
  echo "Ensuring fork exists on GitHub..."
  gh repo fork --clone=false 2>/dev/null || echo "Fork already exists or check skipped."

  # 4. Determine the correct Upstream URL
  # We ask GitHub API for the parent repository to be the source of truth,
  # rather than trusting the current local config which might be messed up.
  local upstream_url
  # Try to get parent URL from GitHub API
  local parent_ssh_url
  parent_ssh_url=$(gh repo view --json parent -q .parent.sshUrl 2>/dev/null)

  if [ -n "$parent_ssh_url" ]; then
    # Case A: The repo is a fork, use the real parent
    upstream_url="$parent_ssh_url"
  else
    # Case B: The repo is NOT a fork (or gh couldn't find parent).
    # If the current origin owner is NOT me, assume current origin is the intended upstream.
    if [[ "$current_origin_url" != *"$my_gh_user"* ]]; then
      upstream_url="$current_origin_url"
    else
      echo "Error: Current origin belongs to you, but GitHub says it has no parent."
      echo "Cannot determine upstream. Exiting."
      return 1
    fi
  fi

  # 5. Security/Logic Check: Ensure Upstream is NOT me
  if [[ "$upstream_url" == *"$my_gh_user"* ]]; then
    echo "Aborting: The determined upstream URL ($upstream_url) belongs to you."
    echo "This usually happens if you cloned your own fork initially and it has no parent."
    return 1
  fi

  # 6. Apply Remotes
  local my_fork_url="ssh://git@github.com/$my_gh_user/$repo_name.git"

  echo "Configuring remotes..."
  git-remote-add-or-set-url upstream "$upstream_url"
  git-remote-add-or-set-url origin "$my_fork_url"

  git fetch --all
  git remote -v
}

git-remote-add-pr () {
  # prid="dunhamsteve:markdown-code-blocks"
  prid="$1"

  # Get the current origin URL
  origin=$(git remote get-url origin)
  # Extract the repository name from the origin URL
  reponame=$(basename "$origin" .git)  # Remove the .git suffix

  username=$(echo "$prid" | cut -d ':' -f 1)  # Extract username
  branch=$(echo "$prid" | cut -d ':' -f 2)    # Extract branch
  url="git@github.com:$username/$reponame.git"
  # url="https://github.com/$username/$reponame/tree/$branch"

  git-remote-add-or-set-url "$username" "$url"  # Add or set the remote
  # git fetch --all
  git fetch "$username"                        # Fetch the new remote
  git merge "$username/$branch"                # Merge the specified branch

  echo "Remote $username has been set up with URL: $url"
}
