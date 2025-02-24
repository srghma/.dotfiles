# example
# git-add-fork--url "https://github.com/evertonstz/youtube-upload" master

git-add-fork--url () {
  url="$1"
  branch="$2"
  reponame=$(echo "$url" | sed -E 's|.*github.com/[^/]+/([^/]+).*|\1|')
  username=$(echo "$url" | sed -E 's|.*github.com/([^/]+)/.*|\1|')
  git-add-fork--full "$reponame" "$username" "$branch"
}

# reponame="youtube-upload"
# prid="youtube-upload:master"
# username=$(echo $prid | cut -d ':' -f 1) # srghma
# branch=$(echo $prid | cut -d ':' -f 2)   # master

# git-add-fork--full "srghma" "youtube-upload" "master"
git-add-fork--full () {
  reponame="$1"
  username="$2"
  url="git@github.com:$username/$reponame.git"
  # url="https://github.com/$username/$reponame/tree/$branch"
  # Check if the remote already exists
  if git remote | grep -q "^$username$"; then operation="set-url" else operation="add" fi
  echo git remote "$operation" "$username" "$url"
  git remote "$operation" "$username" "$url"
  git fetch "$username"

  branch="$3"
  if [ -z "$branch" ]; then
    if git ls-remote --exit-code "$username" main &>/dev/null; then
      git merge "$username/main"
    elif git ls-remote --exit-code "$username" master &>/dev/null; then
      git merge "$username/master"
    fi
  else
    git merge "$username/$branch"
  fi
}
