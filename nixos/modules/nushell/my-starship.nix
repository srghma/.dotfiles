{ pkgs, ... }:
let
  starshipInit = pkgs.runCommand "starship.nu" { } ''
    ${pkgs.starship}/bin/starship init nu > "$out"
  '';
in
{
  environment.systemPackages = [ pkgs.starship ];

  programs.nushell.interactiveShellInit = ''
    # Fallback to ~/.config/starship.toml if not already set
    $env.STARSHIP_CONFIG = ($env.STARSHIP_CONFIG? | default ($env.HOME | path join ".config/starship.toml"))

    use ${starshipInit}
  '';
}
