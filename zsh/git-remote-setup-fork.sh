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

gh-repo-create-and-push () {
  # Creates a GitHub repo from current dir, fixes remotes, pushes main.
  # Deletes upstream if it exists (since it might be wrong).
  #
  # Usage:
  #   gh-repo-create-and-push myrepo            # private by default
  #   gh-repo-create-and-push myrepo public
  #   gh-repo-create-and-push myrepo private
  #
  # Requirements: gh authenticated, git repo initialized.

  setopt localoptions errexit pipefail

  local repo_name="$1"
  local visibility="${2:-public}"

  if [ -z "$repo_name" ]; then
    echo "Usage: gh-repo-create-and-push <repo_name> [public|private]"
    return 1
  fi

  if [[ "$visibility" != "public" && "$visibility" != "private" ]]; then
    echo "Error: visibility must be 'public' or 'private'"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: not inside a git repository"
    return 1
  fi

  # ensure gh works
  local my_gh_user
  my_gh_user=$(gh api user -q .login 2>/dev/null)

  if [ -z "$my_gh_user" ] || [[ "$my_gh_user" == "{"* ]]; then
    echo "Error: Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
    return 1
  fi

  echo "GitHub user: $my_gh_user"
  echo "Repo name:   $repo_name"
  echo "Visibility:  $visibility"

  # delete upstream if it exists (can be wrong)
  git remote remove upstream 2>/dev/null || true

  # delete origin if it exists (can be wrong)
  git remote remove origin 2>/dev/null || true

  # create repo on github and set origin
  echo "Creating GitHub repo..."
  if [[ "$visibility" == "public" ]]; then
    gh repo create "$repo_name" --source=. --remote=origin --public
  else
    gh repo create "$repo_name" --source=. --remote=origin --private
  fi

  # ensure main branch
  git branch -M main 2>/dev/null || true

  # push
  echo "Pushing..."
  git push -u origin main

  echo "Done."
  git remote -v
}

git-remote-setup-fork () {
  # 1. Get current authentic GitHub username
  local my_gh_user
  my_gh_user=$(gh api user -q .login)

  # FIX: Check if empty OR if output looks like a JSON error (starts with '{')
  if [ -z "$my_gh_user" ] || [[ "$my_gh_user" == "{"* ]]; then
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
  gh repo fork --clone=false --remote=true 2>/dev/null || echo "Fork already exists or check skipped."

  # 4. Determine the correct Upstream URL
  # We ask GitHub API for the parent repository to be the source of truth,
  # rather than trusting the current local config which might be messed up.
  local upstream_url
  # Try to get parent URL from GitHub API
  local parent_ssh_url
  parent_ssh_url=$(gh repo view --json parent -q .parent.sshUrl 2>/dev/null)

  # Check if we got a valid URL (and not a JSON error or empty string)
  if [ -n "$parent_ssh_url" ] && [[ "$parent_ssh_url" != "{"* ]]; then
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
