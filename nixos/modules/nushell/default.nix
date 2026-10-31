{
  pkgs,
  ...
}:
{
  imports = [
    ./my-zoxide.nix # bc original does have nushell support
    ./my-starship.nix # bc original does load symlinks
    ./carapace.nix # TODO: submit to nixpkgs
  ];

  programs.nushell = {
    enable = true;

    # use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/git/git-completions.nu *
    # use ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/nix/nix-completions.nu *

    interactiveShellInit = ''
      # Git Abbreviations (auto-expands shortcuts on Space)
      use ${pkgs.nu_scripts}/share/nu_scripts/abbreviations/git/git-abbreviations.nu *
    '';
  };

  # programs.starship = {
  #   enable = true;
  #   enableNushellIntegration = true;
  #   # settings = pkgs.lib.importTOML ./starship.toml; # imports your starship.toml directly
  # };

  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };
}
