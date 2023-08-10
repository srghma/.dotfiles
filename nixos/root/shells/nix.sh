alias nf="nix-find"
alias ns="nix-shell"
alias nsc="nix-shell --command"
alias nii="nix-env -i"
alias nir="nix-env -e"
alias niu="nix-env -u '*'"

nix-format () {
  cat "$1" | nix-beautify | tee "$1"
}
