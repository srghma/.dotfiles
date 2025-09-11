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
export PATH="/home/srghma/projects/purescript/.stack-work/install/x86_64-linux-nix/0758bbd929f42d4f66e05e01297cc69e13582002cc47d515e5cef6cbbf752f9d/9.6.6/bin:$PATH"

# .bin
export PATH="$HOME/.bin:$PATH"

DOTFILES="$HOME/.dotfiles"

PROJECT_PATHS=($HOME/projects $HOME/jss)

export MAKEFLAGS="-j5"

# from https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/common-aliases/common-aliases.plugin.zsh
# unalias fd
# unalias n

# eval "$(direnv hook zsh)"

source $HOME/projects/zsh-nr/index.sh
source $HOME/.dotfiles/secrets-ignored/cachixSigningKey.sh

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

# just --completions zsh > ~/.config/completion-for-just.zsh
source ~/.config/completion-for-just.zsh

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

# Convert SSH Git URL to HTTPS GitLab/GitHub URL
git_ssh_to_https_url() {
  local ssh_url="$1"

  # Remove possible prefixes/suffixes
  local host_path="${ssh_url#ssh://git@}"     # remove ssh://git@
  host_path="${host_path#git@}"               # remove git@ (for git@host:path.git form)
  host_path="${host_path%.git}"               # remove .git
  host_path="${host_path/:/\/}"               # convert : to / → git@host:org/repo → host/org/repo

  local host_port="${host_path%%/*}"          # extract host (with port if any)
  local path="${host_path#*/}"                # extract path

  local host="${host_port%%:*}"               # remove port if any

  echo "https://${host}/${path}"
}

function gpo-open() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local url=""

  if git remote get-url upstream &>/dev/null; then
    url=$(git remote get-url upstream)
  else
    url=$(git remote get-url origin)
  fi

  echo "branch: $branch"
  echo "git url: $url"

  local https_url=$(git_ssh_to_https_url "$url")
  local final_url="${https_url}/-/merge_requests/new?merge_request%5Bsource_branch%5D=${branch}"

  echo "Opening: $final_url"
  /run/current-system/sw/bin/xdg-open "$final_url"
}

function sync_current_repo_to_github() {
  export DIRENV_DISABLE=true  # disable direnv temporarily

  local REPO_PATH="$PWD"
  local REPO_NAME=$(basename "$REPO_PATH")
  local GITHUB_USER="sergeynordicresults"

  echo "=== Processing $REPO_PATH ==="

  if git remote get-url upstream &>/dev/null; then
    echo "🔁 Detected forked repo (has upstream). Forking..."

    local UPSTREAM_URL=$(git remote get-url upstream)
    local REPO_FULLNAME=$(echo "$UPSTREAM_URL" | sed -E 's#(.*:|.*github.com[:/])##' | sed 's/.git$//')

    gh repo fork "$REPO_FULLNAME" --clone=false --remote=false || echo "⚠️  Already forked or error"
  else
    echo "🧪 Not a fork. Checking if repo exists under $GITHUB_USER..."

    if ! gh repo view "$GITHUB_USER/$REPO_NAME" &>/dev/null; then
      echo "🆕 Creating new repo $GITHUB_USER/$REPO_NAME"
      git remote remove origin 2>/dev/null || true
      gh repo create "$GITHUB_USER/$REPO_NAME" --public --source=. --remote=origin --push
    else
      echo "✅ Repo already exists at $GITHUB_USER/$REPO_NAME"
    fi
  fi

  echo "🔗 Setting origin to HTTPS"
  git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

  local CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
  if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "🌿 Renaming branch $CURRENT_BRANCH to main"
    git branch -M main
  fi

  echo "🚀 Pushing to origin"
  git push -u origin main || echo "⚠️  Push failed (maybe already pushed)"

  echo "✅ Done: $REPO_NAME"
}

tscfedit() {
  local tmpfile=$(mktemp)
  tsc --noEmit > "$tmpfile"
  local files
  files=($(grep -oE '^src/[^(]+' "$tmpfile" | sort -u))
  if (( ${#files[@]} )); then
    nvim "${files[@]}"
  else
    echo "No TS errors found."
  fi
  rm -f "$tmpfile"
}
