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
