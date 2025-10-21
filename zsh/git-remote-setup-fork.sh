git-remote-add-or-set-url() {
  local remote_name="$1"
  local url="$2"

  # Check if the remote exists
  if git remote get-url "$remote_name" &>/dev/null; then
    operation="set-url"
  else
    operation="add"
  fi

  # Execute the appropriate command
  git remote "$operation" "$remote_name" "$url"
}

git-remote-setup-fork () {
  origin=$(git remote get-url origin)
  reponame=$(basename "$origin")
  git remote --verbose && git branch -vv

  # Fork the repository using the GitHub CLI
  echo "Forking repository on GitHub..."
  gh repo fork "$origin" --clone=false

  echo "Current origin $origin becomes upstream"

  # Check if the upstream remote already exists and matches the origin
  if git remote get-url upstream 2>/dev/null | grep -q "$origin"; then
    echo "Upstream is already set as expected. Doing nothing."
    return
  fi

  # Add or update the upstream remote
  git-remote-add-or-set-url upstream "$origin"

  # Set the origin to your fork
  git-remote-add-or-set-url origin "ssh://git@github.com/$USER/$(basename "$(git remote get-url origin)")"

  git fetch --all

  git-remote-add-or-set-url origin-old "ssh://git@github.com/srghma-old/$(basename "$(git remote get-url origin)")"

  echo "Updated remotes: origin set to your fork, upstream set to the original repo."
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
