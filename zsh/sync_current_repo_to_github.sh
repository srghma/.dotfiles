function sync_current_repo_to_github() {
  export DIRENV_DISABLE=true  # disable direnv temporarily

  local REPO_PATH="$PWD"
  local REPO_NAME=$(basename "$REPO_PATH")
  local GITHUB_USER="sergeynordicresults"

  echo "=== Processing $REPO_PATH ==="

  if git remote get-url upstream &>/dev/null; then
    echo "🔁 Detected forked repo (has upstream). Forking..."

    local UPSTREAM_URL=$(git remote get-url upstream)
    local REPO_FULLNAME=$(echo "$UPSTREAM_URL" | sed -E 's#(.*:|.*github.com[:/])##' | sed 's/.git$//')

    gh repo fork "$REPO_FULLNAME" --clone=false --remote=false || echo "⚠️  Already forked or error"
  else
    echo "🧪 Not a fork. Checking if repo exists under $GITHUB_USER..."

    if ! gh repo view "$GITHUB_USER/$REPO_NAME" &>/dev/null; then
      echo "🆕 Creating new repo $GITHUB_USER/$REPO_NAME"
      git remote remove origin 2>/dev/null || true
      gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --remote=origin --push
    else
      echo "✅ Repo already exists at $GITHUB_USER/$REPO_NAME"
    fi
  fi

  echo "🔗 Setting origin to HTTPS"
  git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

  local CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "🌿 Renaming branch $CURRENT_BRANCH to main"
    git branch -M main
  fi

  echo "🚀 Pushing to origin"
  git push -u origin main || echo "⚠️  Push failed (maybe already pushed)"

  echo "✅ Done: $REPO_NAME"
}
