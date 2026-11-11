{ pkgs, ... }:
let
  zoxideInit = pkgs.runCommand "zoxide.nu" { } ''
    ${pkgs.zoxide}/bin/zoxide init nushell \
      | sed 's|\^zoxide |^${pkgs.zoxide}/bin/zoxide |g' \
      > "$out"
  '';
in
{
  environment.systemPackages = [ pkgs.zoxide ];

  programs.nushell.interactiveShellInit = ''
    source ${zoxideInit}
  '';
}
