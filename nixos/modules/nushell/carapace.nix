{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkPackageOption;
  inherit (lib.modules) mkIf mkAfter;
  inherit (lib.meta) getExe;

  cfg = config.programs.carapace;

  nushellInitFile = pkgs.runCommand "carapace-nushell-config.nu" { } ''
    ${getExe cfg.package} _carapace nushell > "$out"
  '';

in
{
  options.programs.carapace = {
    enable = mkEnableOption "Carapace, a multi-shell completion generator";
    package = mkPackageOption pkgs "carapace" { };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };
    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };
    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };
    enableXonshIntegration = mkEnableOption "Xonsh integration" // {
      default = true;
    };
    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    programs = {
      bash.interactiveShellInit = mkIf cfg.enableBashIntegration (mkAfter ''
        source <(${getExe cfg.package} _carapace bash)
      '');
      zsh.interactiveShellInit = mkIf cfg.enableZshIntegration (mkAfter ''
        source <(${getExe cfg.package} _carapace zsh)
      '');
      fish.interactiveShellInit = mkIf cfg.enableFishIntegration (mkAfter ''
        ${getExe cfg.package} _carapace fish | source
      '');
      xonsh.config = mkIf cfg.enableXonshIntegration ''
        execx($(${getExe cfg.package} _carapace xonsh), 'exec', __xonsh__.ctx, filename='carapace')
      '';
      nushell.interactiveShellInit = mkIf cfg.enableNushellIntegration (mkAfter ''
        source ${nushellInitFile}
      '');
    };
  };
}
