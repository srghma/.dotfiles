{ pkgs, ... }:

# let
#   ohMyPoshInit = pkgs.runCommand "oh-my-posh.nu" { } ''
#     ${pkgs.oh-my-posh}/bin/oh-my-posh init nu --print > "$out"
#   '';
# in
{
  environment.systemPackages = [ pkgs.oh-my-posh ];
  # programs.nushell.interactiveShellInit = ''
  #   $env.POSH_CONFIG = ($env.HOME | path join ".config/oh-my-posh/config.json")
  #
  #   source ${ohMyPoshInit}
  # '';
}
