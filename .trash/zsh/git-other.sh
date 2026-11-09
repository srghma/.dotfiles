bitbucket-delete-repository () {
  curdir=${PWD##*/}
  repo_name=${1:-$curdir}
  curl -X DELETE --user "${BITBUCKET_LOGIN}":"${BITBUCKET_PASS}" https://api.bitbucket.org/2.0/repositories/$USER/$repository
}

github-create-and-upload () {
  curdir=${PWD##*/}
  raw_name=${1:-$curdir}
  # Remove -master or -main suffix if present
  repo_name=$(echo "$raw_name" | sed -E 's/-(master|main)$//')
  # username="sergeynordicresults"
  username="srghma-backup"
  # username="$USER"
  gh repo create "$username/$repo_name" --public
  # curl -u "$username" https://api.github.com/user/repos -d "{\"name\":\"$repo_name\"}"
  git remote rm origin
  git remote add origin "git@github.com:$username/$repo_name.git"
  github-push-all
}

github-push-all () {
  git push --set-upstream origin --all
  git push --set-upstream origin --tags
}

git-diff-full-context-wihout-diff-so-fancy () {
  file_path=$@
  git diff -U$(wc -l $file_path) | less
}
