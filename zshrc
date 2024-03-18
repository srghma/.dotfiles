# from https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/common-aliases/common-aliases.plugin.zsh
# unalias fd

# eval "$(direnv hook zsh)"

source $HOME/projects/zsh-nr/index.sh

for file in $HOME/.dotfiles/zsh/*.sh; do
  source $file
done

export EDITOR="nvim"

function touch-safe {
  for f in "$@"; do
    [ -d $f:h ] || mkdir -p $f:h && command touch $f
  done
}
# alias touch=touch-safe

function n {
  touch-safe $@
  nvim $@
}

# Function to recursively migrate Spago projects
function spago_migrate_recursive() {
  # Find directories with a file named spago.dhall
  find . -type f -name 'spago.dhall' -exec sh -c '
    for file do
      # Change directory to the directory containing spago.dhall
      cd "$(dirname "$file")" || exit
      # Execute spago-migrate
      spago-migrate
    done
  ' sh {} +
}
