{
  # pkgs,
  ...
}:

{
  # time.timeZone = "Atlantic/Canary";
  # time.timeZone = "Europe/Kiev";
  # time.timeZone = "Europe/Madrid";
  time.timeZone = "Asia/Bangkok";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  environment.variables = {
    EDITOR = "nvim";
    GTK_THEME = "Adwaita:dark";
  };

  programs.nix-ld.enable = true; # for nvim codeium
  programs.direnv = {
    enable = true;
    silent = false;
    loadInNixShell = true;
    nix-direnv.enable = true;
  };
}
