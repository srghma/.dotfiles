bitbucket-delete-repository () {
  curdir=${PWD##*/}
  repo_name=${1:-$curdir}
  curl -X DELETE --user "${BITBUCKET_LOGIN}":"${BITBUCKET_PASS}" https://api.bitbucket.org/2.0/repositories/$USER/$repository
}

github-create-and-upload () {
  curdir=${PWD##*/}
  repo_name=${1:-$curdir}
  username=$USER
  curl -u $username https://api.github.com/user/repos -d "{\"name\":\"$repo_name\"}"
  git remote rm origin
  git remote add origin git@github.com:$username/$repo_name.git
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
