{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Google Antigravity IDE from flake input
    google-antigravity-ide-no-fhs

    # Core Editors & Dev Tools
    vscode
    neovim
    git
    gh
    delta
    bun
    fzf
    ripgrep
    fd
    jq
    carapace
    wezterm
    # starship

    # System & GUI utilities
    libnotify
    procps
    lsof
    xclip
    xsel # for nvim copy to clipboard
    unzip
    zip
    htop
    ripgrep
  ];
}
