repos=(
  # "purescript-polyform/polyform"
  # "purescript-polyform/batteries-core"
  # "purescript-polyform/batteries-json"
  # "purescript-polyform/batteries-env"
  # "purescript-polyform/batteries-urlencoded"
  "purescript-polyform/form-machine"
  # "paluh/purescript-js-unsafe-stringify"
)

mkdir -p ~/projects/purescript-polyform

for repo in "${repos[@]}"; do
  if [ -z "$repo" ]; then
      repo=$(git remote get-url upstream | sed 's|.*github\.com/\(.*\)|\1|' | sed 's|\.git$||')
  fi
  echo "Repository: $repo"
  repo_org=$(echo "$repo" | cut -d'/' -f1)
  repo_name=$(echo "$repo" | cut -d'/' -f2)
  fork="https://github.com/$repo_org/$repo_name"

  # gh repo fork "$repo" --remote=false
  # cd "$HOME/projects/purescript-polyform/"
  # # git clone "$fork" "$repo_name"
  cd "$HOME/projects/purescript-polyform/$repo_name"
  # git-remote-setup-fork
  spago-migrate
  cp -r /home/srghma/projects/purescript-bytestrings/.github ./

  # mkdir -p "./test/Test"
  # find ./test -mindepth 1 -maxdepth 1 ! -name 'Test' -exec mv {} ./test/Test/ \;

  sd 'name:.*' "name: $repo_name" spago.yaml
  sd 'url: https://raw.githubusercontent.com/.*' 'registry: 60.4.0' spago.yaml
  sd 'registry: .*' 'registry: 60.4.0' spago.yaml
  sd 'registry: .*' 'registry: 60.4.0' spago.yaml
  sd 'github.com/paluh' 'github.com/srghma' spago.yaml
  sd 'github.com/paluh' 'github.com/srghma' spago.yaml
  sd 'ref: .*' 'ref: master' spago.yaml
  ([ -f "package.json" ] && npm-check-updates -u || true)

  # rm -frd .spago
  rm -f bower.json packages.dhall spago.dhall

  lebab --replace src --transform commonjs
  lebab --replace test --transform commonjs

  purs-tidy-module-name format-in-place --src src --src test
  spago upgrade --migrate
  spago install
  spago build --censor-stats --strict --pedantic-packages
  spago test --offline --censor-stats --strict --pedantic-packages -- --censor-codes=UserDefinedWarning

  # gaa && gc -m 'feat: migrate to spago@next' && gp
  branch_name=$(git rev-parse --abbrev-ref HEAD)
  # gh pr create --base main --head "$branch_name" --title "feat: migrate to spago@next" --body "can I be added as maintainer to this repo? to push new versions to registry if something"

  # gaa && gc -m 'feat: migrate to spago@next'
  # purs-tidy format-in-place src/**/*.purs test/**/*.purs
  # ### gaa && gc!
  # gaa && gc -m 'purs-tidy format-in-place src/**/*.purs test/**/*.purs'
  # gp
  #
  # # Get the current repository name from the git remote
  # pr_title=$(echo "feat: migrate to spago@next" | jq -sRr @uri)
  # pr_body=$(echo "can I be added as maintainer to this repo? to push new versions to registry if something" | jq -sRr @uri)
  # url="https://github.com/${repo}/compare/master...srghma:${repo#*/}:master?expand=1&title=${pr_title}&body=${pr_body}"
  # echo "Opening PR for $repo_name..."
  # xdg-open "$url"
done
