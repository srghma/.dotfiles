{ pkgs, ... }:
let
  zoxideInit = pkgs.runCommand "zoxide.nu" { } ''
    ${pkgs.zoxide}/bin/zoxide init nushell > "$out"
  '';
in
{
  environment.systemPackages = [ pkgs.zoxide ];

  programs.nushell.interactiveShellInit = ''
    source ${zoxideInit}
  '';
}
