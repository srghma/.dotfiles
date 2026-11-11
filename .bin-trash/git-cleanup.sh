#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# --- CONFIGURATION (Space-separated lists) ---
LIST_OF_EMAILS="sergey@nordicresults.com srghma@gmail.com srghma2@gmail.com"
LIST_OF_EMAIL_PREFIXES="srghma"
LIST_OF_USERNAMES="srghma"

# Global state variables
AUTHOR_FLAGS=""
LOCAL_TO_DELETE=""
LOCAL_DELETE_COUNT=0
REMOTE_TO_DELETE=""
REMOTE_DELETE_COUNT=0

# --- VALIDATIONS & INITIALIZATION ---

ensure_git_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not inside a git repository." >&2
    exit 1
  fi
}

ensure_master_branch() {
  if ! git show-ref --verify --quiet refs/heads/master; then
    echo "Error: 'master' branch does not exist locally." >&2
    exit 1
  fi
}

build_author_flags() {
  # Merge configuration lists into a flat string of Git author options
  for email in $LIST_OF_EMAILS; do
    AUTHOR_FLAGS="$AUTHOR_FLAGS --author=$email"
  done
  for prefix in $LIST_OF_EMAIL_PREFIXES; do
    AUTHOR_FLAGS="$AUTHOR_FLAGS --author=$prefix"
  done
  for username in $LIST_OF_USERNAMES; do
    AUTHOR_FLAGS="$AUTHOR_FLAGS --author=$username"
  done
}

count_user_commits() {
  _base="$1"
  _target="$2"
  # AUTHOR_FLAGS is unquoted so word splitting expands it into separate options
  git log "$_base".."$_target" $AUTHOR_FLAGS --oneline 2>/dev/null | wc -l | tr -d ' '
}

# --- SCANNING LOGIC ---

scan_local_branches() {
  echo "Scanning local branches..."
  for b in $(git branch --format='%(refname:short)'); do
    if [ "$b" = "master" ]; then
      continue
    fi

    commit_count=$(count_user_commits "master" "$b")

    if [ "$commit_count" -eq 0 ]; then
      LOCAL_TO_DELETE="$LOCAL_TO_DELETE $b"
      LOCAL_DELETE_COUNT=$((LOCAL_DELETE_COUNT + 1))
    fi
  done
}

scan_remote_branches() {
  echo "Fetching latest status from origin..."
  git fetch origin --prune

  echo "Scanning remote branches on 'origin'..."
  for r in $(git branch -r --format='%(refname:short)' | grep '^origin/'); do
    b_remote="${r#origin/}"

    if [ "$b_remote" = "master" ] || [ "$b_remote" = "HEAD" ]; then
      continue
    fi

    # Compare against remote master if it exists, otherwise fall back to local master
    base="master"
    if git show-ref --verify --quiet refs/remotes/origin/master; then
      base="origin/master"
    fi

    commit_count=$(count_user_commits "$base" "$r")

    if [ "$commit_count" -eq 0 ]; then
      REMOTE_TO_DELETE="$REMOTE_TO_DELETE $b_remote"
      REMOTE_DELETE_COUNT=$((REMOTE_DELETE_COUNT + 1))
    fi
  done
}

# --- INTERACTIVE DELETIONS ---

handle_local_deletion() {
  printf "\n=== Local Branches to be DELETED ===\n"
  if [ "$LOCAL_DELETE_COUNT" -eq 0 ]; then
    echo "None"
    return
  fi

  for b in $LOCAL_TO_DELETE; do
    echo "  - $b"
  done

  printf "\nDelete locally? (y/N): "
  read -r reply
  case "$reply" in
    [Yy]* )
      CURRENT_BRANCH=$(git branch --show-current)
      printf "\nDeleting local branches...\n"
      for b in $LOCAL_TO_DELETE; do
        if [ "$b" = "$CURRENT_BRANCH" ]; then
          echo "Switching to master to delete current branch '$b'..."
          git checkout master
          CURRENT_BRANCH="master"
        fi
        git branch -D "$b"
      done
      ;;
    * )
      echo "Skipped local deletion."
      ;;
  esac
}

handle_remote_deletion() {
  printf "\n=== Remote Branches (origin) to be DELETED ===\n"
  if [ "$REMOTE_DELETE_COUNT" -eq 0 ]; then
    echo "None"
    return
  fi

  for b in $REMOTE_TO_DELETE; do
    echo "  - origin/$b"
  done

  printf "\nDelete remotely? (y/N): "
  read -r reply
  case "$reply" in
    [Yy]* )
      printf "\nDeleting remote branches...\n"
      for b in $REMOTE_TO_DELETE; do
        echo "Deleting remote branch origin/$b..."
        git push origin --delete "$b"
      done
      ;;
    * )
      echo "Skipped remote deletion."
      ;;
  esac
}

# --- MAIN CONTROLLER ---

main() {
  ensure_git_repository
  ensure_master_branch
  build_author_flags

  scan_local_branches
  scan_remote_branches

  handle_local_deletion
  handle_remote_deletion

  printf "\nCleanup workflow finished.\n"
}

main
