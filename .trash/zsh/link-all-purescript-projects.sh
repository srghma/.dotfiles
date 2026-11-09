# What it does:
#
# Example 1:
# $ link-purescript-project $HOME/projects/purescript-web3 eth-core
# Before: ~/projects/purescript-web3/.spago/eth-core/0.0.1 is just a dir
# After: ~/projects/purescript-web3/.spago/eth-core is a symlink to $HOME/projects/purescript-eth-core
#
# Example 2:
# $ link-purescript-project $HOME/projects/purescript-halogen-nextjs hyper TO="$HOME/projects/hyper"
# Before: ~/projects/purescript-halogen-nextjs/.spago/hyper/0.0.1 is just a dir
# After: ~/projects/purescript-halogen-nextjs/.spago/hyper/0.0.1 is a symlink to $HOME/projects/hyper


link-purescript-project () {( set -e
  project="$1"
  depname="$2"

  for ARGUMENT in "$@"
  do
      KEY=$(echo $ARGUMENT | cut -f1 -d=)
      VALUE=$(echo $ARGUMENT | cut -f2 -d=)

      case "$KEY" in
              TO)         TO=${VALUE} ;;
              OTHER_ARGS) OTHER_ARGS=${VALUE} ;;
              *)
      esac
  done

  # echo "TO = $TO"
  # echo "OTHER_ARGS = $OTHER_ARGS"

  to_="${TO:-"$HOME/projects/purescript-$depname"}"

  echo "Project = $project, depname = $depname, to_ = $to_, other_args = $OTHER_ARGS"

  version=$(cd $project && (bash -c "spago $OTHER_ARGS sources" | grep ".spago/$depname/" | sd '[^/]+/[^/]+/([^/]+)/.*' '$1'))

  [ -z "$version" ] && (echo "\e[31mEmpty dir $project/.spago/$depname (to = $to_)\e[0m" && exit 1)

  echo "linking $project/.spago/$depname to $to_ (version = $version)"

  rmf "$project/.spago/$depname" && mkdir -p "$project/.spago/$depname" && ln -s "$to_" "$project/.spago/$depname/$version"
)}

link-purescript-projects-foam () {( set -e
  rm -f $HOME/.node_modules/bin/chanterelle
  # ln -s $HOME/projects/chanterelle/bin/chanterelle $HOME/.node_modules/bin/chanterelle
  ln -s $HOME/projects/chanterelle/chanterelle-bin.sh $HOME/.node_modules/bin/chanterelle

  (rm -f $HOME/projects/chanterelle-halogen-template/node_modules/.bin/parcel && ln -s $HOME/projects/chanterelle-halogen-template/node_modules/parcel-bundler/bin/cli.js $HOME/projects/chanterelle-halogen-template/node_modules/.bin/parcel || true)

  # cd $HOME/projects/purescript-web3           && pwd && git branch -l
  # cd $HOME/projects/purescript-solc           && pwd && git branch -l
  # cd $HOME/projects/purescript-web3-generator && pwd && git branch -l
  # cd $HOME/projects/chanterelle               && pwd && git branch -l

  # cd $HOME/projects/purescript-web3           && spago build
  # cd $HOME/projects/purescript-solc           && spago build
  # cd $HOME/projects/purescript-web3-generator && spago build
  # cd $HOME/projects/chanterelle               && spago build

  # cd $HOME/projects/purescript-web3              && git push
  # cd $HOME/projects/purescript-solc              && git push
  # cd $HOME/projects/purescript-web3-generator    && git push
  # cd $HOME/projects/chanterelle                  && git push -f
  # cd $HOME/projects/chanterelle-halogen-template && git push

  cd $HOME/projects/purescript-web3              && gh browse --branch master --no-browser --repo srghma/purescript-web3
  cd $HOME/projects/purescript-solc              && gh browse --branch master --no-browser --repo srghma/purescript-solc
  cd $HOME/projects/purescript-web3-generator    && gh browse --branch tidy --no-browser --repo srghma/purescript-web3-generator
  cd $HOME/projects/chanterelle                  && gh browse --branch master --no-browser --repo srghma/chanterelle

  link-purescript-project $HOME/projects/purescript-web3 eth-core

  link-purescript-project $HOME/projects/purescript-solc eth-core

  link-purescript-project $HOME/projects/purescript-web3-generator eth-core
  link-purescript-project $HOME/projects/purescript-web3-generator web3

  link-purescript-project $HOME/projects/chanterelle eth-core
  link-purescript-project $HOME/projects/chanterelle web3
  link-purescript-project $HOME/projects/chanterelle web3-generator

  link-purescript-project $HOME/projects/chanterelle-halogen-template eth-core
  link-purescript-project $HOME/projects/chanterelle-halogen-template web3
  link-purescript-project $HOME/projects/chanterelle-halogen-template web3-generator
  link-purescript-project $HOME/projects/chanterelle-halogen-template solc
  link-purescript-project $HOME/projects/chanterelle-halogen-template chanterelle TO="$HOME/projects/chanterelle"

  # link-purescript-project $HOME/projects/purescript-servant
  # link-purescript-project $HOME/projects/purescript-websocket-simple
  # link-purescript-project $HOME/projects/purescript-geohash
  # link-purescript-project $HOME/projects/purescript-web-mercator
  # link-purescript-project $HOME/projects/purescript-deck-gl
  # link-purescript-project $HOME/projects/purescript-react-map-gl
)}
