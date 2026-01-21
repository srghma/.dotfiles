# gem
# GEM_PATH="$GEM_HOME"
# export PATH="$GEM_HOME/bin:$PATH"

# npm/yarn
export PATH="$HOME/.node_modules/bin:$PATH"

# npm/yarn local
export PATH="./node_modules/.bin:$PATH"

export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/projects/spago-yaml-generate/bin:$PATH"
# export PATH="/home/srghma/projects/purescript/.stack-work/install/x86_64-linux-nix/0758bbd929f42d4f66e05e01297cc69e13582002cc47d515e5cef6cbbf752f9d/9.6.6/bin:$PATH"

# .bin
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/projects/nixpkgs/result/bin:$PATH"

DOTFILES="$HOME/.dotfiles"

PROJECT_PATHS=($HOME/projects $HOME/jss $HOME/trivial-rs)

export MAKEFLAGS="-j5"

# from https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/common-aliases/common-aliases.plugin.zsh
# unalias fd
# unalias n
alias l="lsd -la"
alias ls="lsd -la"
alias lt='lsd --tree'
# alias ls="ls --hyperlink=auto --color=auto"

# eval "$(direnv hook zsh)"

source $HOME/projects/zsh-nr/index.sh
# source $HOME/.dotfiles/secrets-ignored/cachixSigningKey.sh

for file in $HOME/.dotfiles/zsh/*.sh; do
  source $file
done

# tmux-window-name() {
#   (/nix/store/3zg0dvhh2cfk59wh3d1ryhdzx7b5xlqg-tmuxplugin-tmux-window-name-2024-03-08/share/tmux-plugins/tmux-window-name/scripts/rename_session_windows.py &)
# 	# ($TMUX_PLUGIN_MANAGER_PATH/tmux-window-name/scripts/rename_session_windows.py &)
# }
# add-zsh-hook chpwd tmux-window-name

# export TERM=xterm-kitty

# export EDITOR="lvim"

function touch-safe {
  for f in "$@"; do
    [ -d $f:h ] || mkdir -p $f:h && command touch $f
  done
}
# alias touch=touch-safe

function mkdircd {
  mkdir -p "$@"
  cd "$@"
}

function n {
  touch-safe $@
  nvim $@
}

# # Function to recursively migrate Spago projects
# function spago_migrate_recursive() {
#   # Find directories with a file named spago.dhall
#   find . -type f -name 'spago.dhall' -exec sh -c '
#     for file do
#       # Change directory to the directory containing spago.dhall
#       cd "$(dirname "$file")" || exit
#       # Execute spago-migrate
#       spago-migrate
#     done
#   ' sh {} +
# }

alias nii="nix profile install"
alias p="pnpm"
alias npm="pnpm"

path_array=(
  "$HOME/.dotfiles/bin"
  "$HOME/projects/spago-yaml-generate/bin"
  "$HOME/projects/idris2-pack/result/bin"
  "$HOME/projects/Idris2/result/bin"
  # "/nix/store/sk1959yrzisz1qf4p4sgjf55mdngvdqh-idris2-lsp-2024-01-21/bin/"
  "$HOME/projects/zed/result/bin"
  "$HOME/projects/idris2-lsp/result/bin"
  # "$HOME/projects/idris2-lsp/result-newest-not-working/bin"
  # "$HOME/projects/idris2-lsp/result-old-working/bin"
)

export PATH=$(IFS=:; echo "${path_array[*]}"):$PATH

fpath=($HOME/.my-completions $fpath)

# alias spago="$HOME/projects/spago/bin/index.dev.js"

## https://pnpm.io/completion
# pnpm completion zsh > ~/.config/completion-for-pnpm.zsh
source ~/.config/completion-for-pnpm.zsh

# bun completions zsh > ~/.config/completion-for-bun.zsh
source ~/.config/completion-for-bun.zsh

# just --completions zsh > ~/.config/completion-for-just.zsh
# source ~/.config/completion-for-just.zsh

# unalias z
# eval "$(zoxide init zsh)"

# pnpm
export PNPM_HOME="/home/srghma/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# export LD_LIBRARY_PATH=$(pwd)/.lake/packages/LeanCopilot/.lake/build/lib:$LD_LIBRARY_PATH

# export LANG=en_US.UTF-8
# export LC_ALL=en_US.UTF-8

###############################
# IMPORTANT: kitty-scrollback.nvim only supports zsh 5.9 or greater for command-line editing,
# please check your version by running: zsh --version
# add the following environment variables to your zsh config (e.g., ~/.zshrc)
autoload -Uz edit-command-line
zle -N edit-command-line
function kitty_scrollback_edit_command_line() {
  local VISUAL='/home/srghma/.local/share/nvim/lazy/kitty-scrollback.nvim/scripts/edit_command_line.sh'
  zle edit-command-line
  zle kill-whole-line
}
zle -N kitty_scrollback_edit_command_line
bindkey '^x^e' kitty_scrollback_edit_command_line
# [optional] pass arguments to kitty-scrollback.nvim in command-line editing mode
# by using the environment variable KITTY_SCROLLBACK_NVIM_EDIT_ARGS
# export KITTY_SCROLLBACK_NVIM_EDIT_ARGS=''
source $HOME/.dotfiles/secrets/aristotle-lean-key.sh

# ln -sf $HOME/projects/mm0/mm0-hs/.stack-work/dist/x86_64-linux-nix/ghc-9.10.3/build/mm0-hs/mm0-hs ~/.dotfiles/bin/mm0-hs
# ln -sf /home/srghma/projects/mm0/mm0-rs/target/release/mm0-rs ~/.dotfiles/bin/mm0-rs
