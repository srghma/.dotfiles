{
  pkgs,
  ...
}@args:
{
  imports = [
    ../modules/unifiedGtkQtTheme.nix
    ../modules/access-tokens.nix
    ../modules/hibernate-at-time.nix
    # ../modules/disable-main-keyboard.nix
    # ../modules/direnv-from-lorri-repo.nix
    ../modules/cachix.nix
    # ../modules/cast-from-android.nix
    ../modules/qemu.nix
    ../modules/obs.nix
    ../modules/dropbox.nix
    # ../modules/webcamoid.nix
    # ../modules/bluetooth-audio.nix
    ../modules/tmux.nix
    # ../modules/miracast.nix
    # ../modules/vicuna.nix

    ./configuration-generated.nix
    ./hardware-configuration.nix
    ./systemd/disable-touchpad.nix
  ];

  # unifiedGtkQtTheme = {
  #   enable = true;
  # };

  # environment.enableAllTerminfo = true;
  environment.variables = {
    EDITOR = "nvim";
    GTK_THEME = "Adwaita:dark";
  };

  environment.etc."resolvconf.conf".text = ''
    name_servers='8.8.8.8'
  '';

  qt = {
    enable = true;
    # platformTheme = "gnome";
    platformTheme = "qt5ct";
    style = "adwaita-dark";
  };

  services = import ./services args;
  fonts = import ./fonts args;
  users = import ./users args;

  # tilde.workstation.disable_main_keyboard.enable = true;
  # tilde.username = "srghma";

  # location = {
  #   latitude = 47.517201;
  #   longitude = 35.859375;
  # };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware = {
    bluetooth.enable = false;

    graphics = {
      enable = true;
      # driSupport32Bit = true; # for steam
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;

      # TODO: what is using this?
      permittedInsecurePackages = [
        # for anbox
        # "libdwarf-20181024"
        # for goldendict
        # "qtwebkit-5.212.0-alpha4"
      ];
    };

    overlays = [ (import ../utils/overlay.nix) ];
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  programs = {
    firejail.enable = true;
    nix-ld.enable = true; # for nvim codeium

    # droidcam.enable = true;
    direnv.enable = true;
    direnv.silent = false;
    direnv.loadInNixShell = true;
    direnv.nix-direnv.enable = true;

    gnupg.agent.enable = true;
    # gnome-documents.enable = false;
    seahorse.enable = false;
    gnome-terminal.enable = false;

    java.enable = true;
    # chromium.enable = true; # add chrome and chromium config files to /etc

    adb.enable = true; # from https://nixos.wiki/wiki/Android

    ssh = {
      # don't forget to `ssh-add` to add key to keychain
      startAgent = true;
    };

    # cachix = {
    #   enable = true;
    #   cachixSigningKey = import ../../secrets-ignored/cachixSigningKey.nix;
    # };

    bash = {
      interactiveShellInit = ''
        source ${./shells/docker-compose.sh}
        source ${./shells/docker.sh}
        source ${./shells/git.sh}
      '';
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;

      interactiveShellInit = ''
        source ${./zsh/movements.sh}
        source ${./shells/docker-compose.sh}
        source ${./shells/docker.sh}
        source ${./shells/git.sh}
        DEFAULT_USER="srghma"
        autoload -U zmv
        VI_MODE_DISABLE_CLIPBOARD=true
      '';

      ohMyZsh = {
        enable = true;
        theme = "agnoster";
        preLoaded = ''
          export FZF_ALT_C_COMMAND=""
        '';
        plugins = [
          ## appearence
          "colorize"
          "compleat"
          "common-aliases"
          # zsh-autosuggestions
          # zsh-completions

          ## editing
          "vi-mode"

          ## navigation
          "history-substring-search"
          "dircycle"
          "dirpersist"
          "pj"
          "zsh-navigation-tools"

          ## programs
          # "tmux"
          # "git"

          ## nixos
          # NOTE: nix-zsh-completions already installed via `programs.zsh.enableCompletion = true`
          "systemd"
          "sudo"

          ## ruby
          # "bundler"
          # "gem"
          # rvm
          # rake-fast

          ## haskell
          # stack

          ## docker
          "docker"
          "docker-compose"

          ## js
          # yarn
          "direnv"
          "fzf"
          "zoxide"
        ];
      };
    };

    command-not-found.enable = true;
  };

  networking = {
    hostName = "machine";
    hostId = "36132bc9"; # generated with `head -c 8 /etc/machine-id`

    # wireless.enable = true;
    networkmanager.enable = true;

    firewall = {
      # for libvirtd (https://nixos.org/nixops/manual/#idm140737318329504)
      # checkReversePath = false;

      enable = false;
      # allowPing = true;

      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ]; # for nixpkgsMaster.pkgs.kdeconnect
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ]; # for nixpkgsMaster.pkgs.kdeconnect

      allowedTCPPorts = [
        3131 # deskreen
        5900 # bVNC default port, also qemu `sudo lsof -i :5900`
        5901 # bVNC port2
        # 5432
        # 34567 # MY PORT FOR WIFI USE
        # 33927 # Error: connection refused: localtunnel.me:33927 (check your firewall settings) at Socket.<anonymous> (/home/srghma/.node_modules/lib/node_modules/localtunnel/lib/TunnelCluster.js:52:11)
      ];

      allowedUDPPorts = [
        3131 # deskreen
        # 40118 # https://github.com/rfc2822/GfxTablet
      ];
    };

    hosts =
      let
        block =
          builtins.concatMap
            (domain: [
              domain
              ("www." + domain)
            ])
            [
              # "twitter.com"
              # "x.com"
              # "youtube.com"
              # "m.youtube.com"
              # "telegram.org"
              # "web.telegram.org"
              # "zws2.web.telegram.org"
              # "zws2-1.web.telegram.org"
              # "pikabu.ru"
              # "reddit.com"
            ];
      in
      {
        "::0" = block;
        "0.0.0.0" = block;
        # "192.168.250.1" = [ "srghma-chinese.github.io" "srghma-chinese2.github.io" ];
      };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

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
    # inputMethod = { enabled = "fcitx5"; fcitx5.engines = with pkgs.fcitx-engines; [ rime libpinyin m17n cloudpinyin ]; };
  };

  # time.timeZone = "Atlantic/Canary";
  # time.timeZone = "Europe/Kiev";
  # time.timeZone = "Europe/Madrid";
  time.timeZone = "Asia/Bangkok";

  nix.gc.automatic = true;

  # allows use of builtins.exec
  # allow-unsafe-native-code-during-evaluation = true
  # nix.extraOptions = ''
  #   # by default nix deletes build dependencies and leaves only resuliting package, this prevents it, useful for development
  #   # keep-outputs = true
  #   # keep-derivations = true
  #   allow-import-from-derivation = false
  # '';

  # Free up to 1GiB whenever there is less than 100MiB left.
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # sandbox = "relaxed";

    # max-jobs is about the number of derivations that Nix will build in parallel, while cores is about parallelism inside a derivation, e.g. what make -j will use
    max-jobs = "auto";

    # 0 means to use all available cores
    cores = 0;

    auto-optimise-store = true;

    # FIXME: https://cache.nixos.org already exists in standard config and should not be added by hand, but rather merged
    substituters = [
      # "https://cache.iog.io"
      "https://cache.nixos.org"
      # "https://cachix.cachix.org"
      # "https://srghma.cachix.org"
      # "https://nixcache.reflex-frp.org"
      # "https://lorri-test.cachix.org"
      # "https://nix-tools.cachix.org"
      # "https://devenv.cachix.org"
      # "https://digitallyinduced.cachix.org"
      "https://gh-nix-idris2-packages.cachix.org"
    ];

    trusted-public-keys = [
      # "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      # "srghma.cachix.org-1:EUHKjTh/WKs49hFtw6bwDE9oQLeX5afml0cAKc97MbI="
      # "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
      # "lorri-test.cachix.org-1:wZCd/aYaK5pMR0odlnNIdinNTR+3mz3A60NYlFiCeO0="
      # "nix-tools.cachix.org-1:ebBEBZLogLxcCvipq2MTvuHlP7ZRdkazFSQsbs0Px1A="
      # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      # "digitallyinduced.cachix.org-1:y+wQvrnxQ+PdEsCt91rmvv39qRCYzEgGQaldK26hCKE="
      "gh-nix-idris2-packages.cachix.org-1:iOqSB5DrESFT+3A1iNzErgB68IDG8BrHLbLkhztOXfo="
    ];

    trusted-users = [
      "root"
      "srghma"
    ];
  };

  # use unstable
  nix.package = pkgs.nixVersions.latest;

  virtualisation.docker = {
    enable = true;
    enableNvidia = false; # https://github.com/fauxpilot/fauxpilot
    # liveRestore = false;
    # storageDriver = "overlay"; # TODO: use overlay2, delete before switch /var/lib/docker
    # extraOptions = "--host=0.0.0.0:2375";
    # extraOptions = "-H unix:///var/run/docker.sock";
  };

  # virtualisation.anbox.enable = false;

  ### DONT USE virtualbox, USE nixos/modules/qemu.nix!!
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true; # for forwarding usb

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # system.activationScripts.preventCurrentSystemPackagesIfdsFromCollecting = ''
  #   ln -sfn ${pkgs.collectIfdDepsToTextFile environment.systemPackages} /nix/var/nix/gcroots/ifd-deps
  # '';
}
