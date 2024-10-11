# gh repo list purescript-contrib --limit 100 --json name --jq '.[].name' | cat

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  if [ ! -f "$dir/spago.yaml" ]; then
    echo "spago.yaml not found in $dir"
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  if [ ! -f "$dir/test/Test/Main.purs" ]; then
    rm -f "$dir/test/Test.purs"
    cat <<EOF > "$dir/test/Test/Main.purs"
module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)

main :: Effect Unit
main = do
  log "🍕"
  log "You should add some tests."
EOF
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  if [ -f "$dir/spago.yaml" ]; then
    echo "spago.yaml found in $dir"
    cd $dir
    output=$(spago build --censor-stats --strict --pedantic-packages --monochrome 2>&1 >/dev/null)
    echo "$output"
    echo "$output" | grep -E '^spago uninstall|^spago install' | while read -r cmd; do
      echo "Executing: $cmd"
      eval "$cmd"
    done
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  cd $dir
  sd 'rimraf .pulp-cache' 'rimraf .spago' ./package.json
  sd 'pulp build -- --censor-lib --strict' 'spago build --censor-stats --strict --pedantic-packages' ./package.json
  sd 'spago -x test.dhall' 'spago' ./package.json
  sd 'spago build --purs-args=\\"--strict --censor-lib\\"' 'spago build --censor-stats --strict --pedantic-packages' ./package.json
  sd "spago build --purs-args '--censor-lib --strict'" 'spago build --censor-stats --strict --pedantic-packages' ./package.json
  sd " --no-install" ' --offline' ./package.json
  sd " -x ./test.dhall" '' ./package.json
  git add --all
  bower-json-to-spago-yaml
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  cd "$dir"
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  if [ "$current_branch" = "main" ]; then
    sd 'branches: .*' 'branches: [main]' ./.github/workflows/ci.yml
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  cd "$dir" || continue
  if [ -f "bower.json" ]; then
    jq 'del(.dependencies, .devDependencies)' bower.json > bower.tmp && mv -f bower.tmp bower.json
    bower-json-to-spago-yaml
    echo "Updated bower.json in $dir"
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  cd "$dir" || continue
  if [ -f "test.dhall" ]; then
    echo "$dir"
  fi
done

outputdir="$HOME/projects/contrib"
for dir in "$outputdir"/*/; do
  cd "$dir" || continue
  if [ -f "bower.json" ]; then
    node -e "
      const fs = require('fs');
      const path = require('path');
      const filePath = path.resolve('$dir', 'bower.json');

      // Read and parse bower.json
      const bowerData = JSON.parse(fs.readFileSync(filePath, 'utf8'));

      let license;

      // Check if 'license' is an array or a string
      if (Array.isArray(bowerData.license) && bowerData.license.length === 1) {
        license = bowerData.license[0];
      } else if (typeof bowerData.license === 'string') {
        license = bowerData.license;
      } else {
        console.error(\"Error: 'license' must be a string or an array with a single element in \" + filePath);
        process.exit(1);
      }

      // Update the license in bower.json
      bowerData.license = license;

      // Write the updated data back to bower.json
      fs.writeFileSync(filePath, JSON.stringify(bowerData, null, 2), 'utf8');
      console.log('Updated license in bower.json in $dir: ' + license);
    "
  fi
done

repos=(
  purescript-parsing
  purescript-profunctor-lenses
  purescript-aff
  purescript-book
  purescript-rationals
  atom-language-purescript
  purescript-github-actions-toolkit
  purescript-argonaut-core
  purescript-optparse
  purescript-argonaut-codecs
  purescript-js-fetch
  chnglg
  purescript-avar
  purescript-js-bigints
  purescript-css
  purescript-uint
  purescript-fork
  purescript-formatters
  purescript-bigints
  purescript-js-blob
  purescript-arraybuffer
  purescript-vim
  purescript-ace
  purescript-js-abort-controller
  purescript-react
  purescript-int64
  purescript-js-promise-aff
  purescript-coroutines
  purescript-quickcheck-laws
  purescript-affjax-node
  purescript-string-parsers
  purescript-js-promise
  purescript-js-uri
  purescript-react-dom
  purescript-routing
  purescript-js-timers
  purescript-uri
  purescript-affjax-web
  purescript-aff-coroutines
  purescript-affjax
  purescript-aff-bus
  purescript-concurrent-queues
  purescript-argonaut
  purescript-argonaut-traversals
  purescript-argonaut-generic
  purescript-freet
  purescript-these
  purescript-float32
  purescript-js-date
  purescript-now
  purescript-strings-extra
  purescript-precise
  purescript-options
  purescript-unicode
  purescript-pathy
  purescript-colors
  purescript-http-methods
  purescript-form-urlencoded
  purescript-matryoshka
  purescript-fixed-points
  purescript-machines
  purescript-unsafe-reference
  purescript-nullable
  purescript-media-types
  purescript-arraybuffer-types
)

outputdir="$HOME/projects/contrib"
mkdir -p "$outputdir"
repo_org="purescript-contrib"

for repo in "${repos[@]}"; do
  # repo_org=$(echo "$repo" | cut -d'/' -f1)
  # repo_org=$(echo "$repo" | cut -d'/' -f1)
  # repo_name=$(echo "$repo" | cut -d'/' -f2)
  repo_name=$repo
  # fork="https://github.com/$repo_org/$repo_name"
  # echo $fork

  # gh repo fork "$repo_org/$repo_name" --remote=false --clone=false

  # if [ ! -d "$outputdir/$repo_name" ]; then
  #   echo "Directory $outputdir/$repo_name not found, cloning..."
  #   cd "$outputdir"
  #   git clone "$fork" "$repo_name"  # Clone the repository
  # else
  #   echo "Directory $outputdir/$repo_name already exists."
  # fi

  cd "$outputdir/$repo_name"
  # gco -- .github/PULL_REQUEST_TEMPLATE.md
  # gco -- .github/ISSUE_TEMPLATE/

  git-remote-setup-fork

  # if [ -d "./.github/workflows" ]; then
  #   echo "Directory ./.github/workflows exists. Copying ci.yml..."
  #   cp -rf /home/srghma/projects/purescript-bytestrings/.github/workflows/ci.yml ./.github/workflows/ci.yml
  # else
  #   echo "Directory ./.github/workflows does not exist. Copying entire .github directory..."
  #   cp -rf /home/srghma/projects/purescript-bytestrings/.github ./.github
  # fi

  rm -f ./packages.dhall
  # cp -f /home/srghma/projects/contrib/purescript-js-bigints/packages.dhall ./packages.dhall
  echo "https://github.com/purescript/package-sets/releases/download/psc-0.15.4-20221015/packages.dhall sha256:4949f9f5c3626ad6a83ea6b8615999043361f50905f736bc4b7795cba6251927" > ./packages.dhall
  (spago-migrate || true)

  if [ ! -d "./test/Test" ]; then
    mkdir -p "./test/Test"
    find ./test -mindepth 1 -maxdepth 1 ! -name 'Test' -exec mv {} ./test/Test/ \;
  else
    echo "Directory $outputdir/$repo_name/test/Test already exists."
  fi

  sd 'name:.*' "name: ${repo_name#purescript-}" spago.yaml
  sd 'url: https://raw.githubusercontent.com/.*' 'registry: 60.4.0' spago.yaml
  sd 'registry: .*' 'registry: 60.4.0' spago.yaml
  sd 'registry: .*' 'registry: 60.4.0' spago.yaml
  sd 'github.com/paluh' 'github.com/srghma' spago.yaml
  sd 'github.com/paluh' 'github.com/srghma' spago.yaml
  sd 'ref: .*' 'ref: master' spago.yaml
  ([ -f "package.json" ] && npm-check-updates -u || true)

  # # rm -frd .spago
  # rm -f bower.json packages.dhall spago.dhall
  #
  lebab --replace src --transform commonjs
  lebab --replace test --transform commonjs

  npm install
  purs-tidy-module-name format-in-place --src src --src test
  spago upgrade --migrate
  spago install
  rm -fdr .spago output
  spago build --censor-stats --strict --pedantic-packages
  spago test --offline --censor-stats --strict --pedantic-packages -- --censor-codes=UserDefinedWarning
  rm -f packages.dhall spago.dhall
  bower-json-to-spago-yaml

  # gaa && gc -m 'feat: migrate to spago@next' && gp
  # branch_name=$(git rev-parse --abbrev-ref HEAD)
  # gh pr create --base main --head "$branch_name" --title "feat: migrate to spago@next" --body "can I be added as maintainer to this repo? to push new versions to registry if something"

  gco -b update-spago-next
  gaa && gc -m 'feat: migrate to spago@next'
  # purs-tidy format-in-place src/**/*.purs test/**/*.purs lib/src/**/*.purs lib/test/**/*.purs bin/src/**/*.purs bin/test/**/*.purs
  purs-tidy format-in-place src test lib/src lib/test bin/src bin/test
  ### gaa && gc!
  gaa && gc -m 'purs-tidy format-in-place src/**/*.purs test/**/*.purs'
  # gp
  git push --set-upstream origin update-spago-next

  # # Get the current repository name from the git remote
  repo=$(git remote get-url upstream | sed 's|.*github\.com/\(.*\)|\1|' | sed 's|\.git$||')
  echo "Repository: $repo"
  pr_title=$(echo "feat: migrate to spago@next" | jq -sRr @uri)
  # pr_body=$(echo "can I be added as maintainer to this repo? to push new versions to registry if something" | jq -sRr @uri)
  pr_body=""
  echo "Opening PR for $repo_name..."
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  xdg-open "https://github.com/${repo}/compare/main...srghma:${repo#*/}:$current_branch?expand=1&title=${pr_title}"
  xdg-open "https://github.com/srghma/${repo#*/}"
done
