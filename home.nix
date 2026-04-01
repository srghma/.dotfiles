{ pkgs, ... }:

{
  home.username = "srghma";
  home.homeDirectory = "/home/srghma";

  home.stateVersion = "25.11"; # match your system version

  programs.home-manager.enable = true;

  # home.packages = with pkgs; [
  #   neovim
  #   fzf
  #   zoxide
  # ];
  #
  # programs.git.enable = true;
  #
  # programs.zsh.enable = true;
}
