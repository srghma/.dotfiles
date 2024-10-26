git-remote-setup-fork () {
  origin=$(git remote get-url origin)
  reponame=$(basename $origin)
  echo "Current origin $origin becomes upstream"
  git remote-upsert upstream "$origin"
  git remote-upsert origin "ssh://git@github.com/srghma/$reponame"
}

# reponame="idris2-lsp-vscode"
# prid="dunhamsteve:markdown-code-blocks"
# username=$(echo $prid | cut -d ':' -f 1) # srghma
# branch=$(echo $prid | cut -d ':' -f 2)   # master
# url="git@github.com:$username/$reponame.git"
# # url="https://github.com/$username/$reponame/tree/$branch"
# if git remote | grep -q "^$username$"; then operation="set-url" else operation="add" fi
# echo git remote "$operation" "$username" "$url"
# git remote "$operation" "$username" "$url"
# git fetch "$username"
# git merge "$username/$branch"
