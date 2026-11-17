# nix profile install nixpkgs\#yt-dlp --inputs-from ~/.dotfiles
#
# cd ~/.dotfiles; nix flake update
# cd ~/.dotfiles; nix flake update; sudo nixos-rebuild switch --flake ~/.dotfiles --verbose
# sudo nixos-rebuild dry-build --flake ~/.dotfiles --verbose --show-trace
#
# nix repl
# :lf .
# pkgs = inputs.nixpkgs.outputs.legacyPackages."x86_64-linux"
#
## for neovim
# npm i -g vscode-langservers-extracted purs-tidy
{
  description = "A simple NixOS flake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgsStable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
    # nixpkgsVlc4.url = "github:PerchunPak/nixpkgs/vlc4";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgsTelegramOld.url = "github:NixOS/nixpkgs/5df43628fdf08d642be8ba5b3625a6c70731c19c";
    # nixpkgsLocal.url = "git+file:/home/srghma/projects/nixpkgs";
    # nixpkgsMyNeovimNightly.url = "github:srghma/nixpkgs/neovim2";
    # nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
    # kb-light.url = "github:srghma/kb-light";
    # kb-light.flake = false;
    # dunsted-volume.url = "github:srghma/dunsted-volume";
    # dunsted-volume.flake = false;
    # fix-github-https-repo.url = "github:srghma/fix-github-https-repo";
    # fix-github-https-repo.flake = false;
    # image_optim.url = "github:toy/image_optim";
    # image_optim.flake = false;
    # easy-purescript-nix-automatic.url = "github:srghma-backup/easy-purescript-nix-automatic";
    # easy-purescript-nix-automatic.flake = false;
    # purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
    # purescript-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # Idris2.url = "git+file:/home/srghma/projects/Idris2";
    # Idris2.inputs.nixpkgs.follows = "nixpkgs";
    # idris2-pack.url = "git+file:/home/srghma/projects/idris2-pack";
    # idris2-pack.inputs.nixpkgs.follows = "nixpkgs";
    # sops-nix.url = "github:Mic92/sops-nix";
    # sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    zed.url = "github:zed-industries/zed";
    # zed.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    # extra-substituters = [
    #   "https://mio.cachix.org/"
    # ];
    # extra-trusted-public-keys = [
    #   "mio.cachix.org-1:FlupyyLPURqwdRqtPT/LBWKsXY7JKsDkzZQo2K6LeMM="
    # ];
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      nixosConfig = {
        inherit system;
        overlays = [ inputs.nur.overlays.default ];
        config = {
          allowUnfree = true;
        };
      };

      # nixpkgsVlc4 = import inputs.nixpkgsVlc4 nixosConfig;
      # nixpkgsMyNeovimNightly = import inputs.nixpkgsMyNeovimNightly nixosConfig;
      # nixpkgsLocal = import inputs.nixpkgsLocal nixosConfig;
      # nixpkgs = import inputs.nixpkgs nixosConfig;
      nixpkgsStable = import inputs.nixpkgsStable nixosConfig;
      # nixpkgsMaster = import inputs.nixpkgsMaster nixosConfig;
      # nixpkgsTelegramOld = import inputs.nixpkgsTelegramOld nixosConfig;
    in
    {
      nixosConfigurations.machine = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          inputs.home-manager.nixosModules.home-manager
          # inputs.sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [
              (_final: _prev: {
                inherit nixpkgsStable;
                google-antigravity-ide-no-fhs =
                  inputs.antigravity-nix.packages.${system}.google-antigravity-ide-no-fhs;
              })
            ];
          }
          "${inputs.nixos-hardware}/lenovo/ideapad/16iah8"
          ./nixos/root/default.nix
          ./nixos/root/configuration-generated.nix
          ./nixos/root/hardware-configuration.nix
          ./nixos/root/systemd/disable-touchpad.nix
          ./nixos/modules/shared-packages.nix
          ./nixos/modules/shared-default.nix
          # ./nixos/modules/testuservm.nix
          ./nixos/modules/unifiedGtkQtTheme.nix
          ./nixos/modules/my-monitor-is-broken-cut-on-left.nix
          ./nixos/modules/dropbox.nix
          ./nixos/modules/nushell/default.nix
          #./nixos/modules/access-tokens.nix
          #./nixos/modules/hibernate-at-time.nix
          #./nixos/modules/disable-main-keyboard.nix
          #./nixos/modules/direnv-from-lorri-repo.nix
          #./nixos/modules/cachix.nix
          #./nixos/modules/cast-from-android.nix
          #./nixos/modules/qemu.nix
          #./nixos/modules/obs.nix
          #./nixos/modules/webcamoid.nix
          #./nixos/modules/bluetooth-audio.nix
          #./nixos/modules/tmux.nix
          #./nixos/modules/miracast.nix
          #./nixos/modules/vicuna.nix
          (
            {
              pkgs,
              ...
            }:
            let
              # dunsted-volume = pkgs.callPackage inputs.dunsted-volume { };
              # nix-alien-pkgs = inputs.nix-alien-pkgs.packages.${system};
              # kb-light = pkgs.callPackage inputs.kb-light { };
              i3-battery-popup = pkgs.callPackage ./nixos/pkgs/i3-battery-popup { };
              srghma-i3-volume = pkgs.callPackage ./nixos/pkgs/srghma-i3-volume { };
              srghma-i3-screenshot = pkgs.callPackage ./nixos/pkgs/srghma-i3-screenshot { };
              srghma-i3-brightness = pkgs.callPackage ./nixos/pkgs/srghma-i3-brightness { };
              switch_touchpad = pkgs.callPackage ./nixos/pkgs/switch_touchpad { };
              # bifrost = pkgs.callPackage ./nixos/pkgs/bifrost/package.nix { };
              # odin4 = pkgs.callPackage ./nixos/pkgs/odin4 { };
              # browseros = pkgs.callPackage ./nixos/pkgs/browseros { };
              # purescript-overlay = inputs.purescript-overlay.packages.${system};
              # easy-purescript-nix-automatic = import inputs.easy-purescript-nix-automatic {
              #   inherit pkgs;
              # };
            in
            {
              # home-manager.useGlobalPkgs = true;
              # home-manager.useUserPackages = true;
              # home-manager.users.srghma = import ./home.nix;

              environment.systemPackages = with pkgs; [
                # browseros

                # home-manager

                # pulseaudio # for /home/srghma/.dotfiles/bin/my-volume.sh

                # nur.repos.mio.bifrost
                # odin4
                # cd /home/srghma/projects/idris2-pack && nix profile install $(nix build)
                # cd /home/srghma/projects/Idris2 && nix profile install $(nix build)
                # inputs.Idris2.packages.${system}.default
                # inputs.idris2-pack.packages.${system}.default

                # nix-alien-pkgs.nix-alien
                brightnessctl

                telegram-desktop
                google-chrome
                eza
                yazi
                # code-cursor
                # chromium
                # chromium
                #libreoffice
                #inkscape
                # inputs.zed.packages.${system}.default
                # zed-editor
                #ntfs3g
                #alsa-utils

                #kdePackages.okular

                pavucontrol
                conky

                dunst
                copyq
                # yq-go # for tmux joshmedeski/tmux-nerd-font-window-name
                rofi
                pasystray
                scrot
                flameshot
                age
                # anki
                # nixpkgsLocal.pkgs.anki-bin
                xarchiver
                # nixpkgsLocal.pkgs.ngrok

                ## misc
                transmission_4-gtk
                feh
                mpv
                atool
                wget
                gnupg
                thunderbird
                # psmisc
                # lxappearance

                # ranger
                # joshuto
                # termite
                # kitty
                # nixpkgsMyNeovimNightly.pkgs.neovim
                # nixpkgsLocal.pkgs.neovim
                # lunarvim
                # lazygit
                lua-language-server
                code-minimap
                # alejandra
                # nixfmt-classic
                nixfmt
                statix
                selene
                deadnix
                nixd

                # vscode.fhs
                audacious
                # nix

                ## development
                git-lfs
                #git-crypt

                #meld

                # mplayer

                # nodejs_latest # if run bun then "error: No such built-in module: node:sqlite"
                bun
                # nodejs_22
                # pnpm

                # netcat-openbsd # nc -U /var/run/acpid.socket
                openssl

                # xorg.xbacklight
                acpilight

                unar
                unrar
                i3status-rust
                srghma-i3-volume
                srghma-i3-brightness
                srghma-i3-screenshot
                switch_touchpad

                automake
                autoconf
                # autoconf
                gnumake
                gcc
                # inkscape

                poppler-utils
                #docker-compose
                # mkpasswd

                #universal-ctags
                # filezilla
                # firefox
                #asciinema
                #tree
                # youtube-dl
                #tigervnc

                #simplescreenrecorder
                # screencast
                # gtk-recordmydesktop
                # kdenlive
                # kazam

                # vagrant
                # ib-tws
                # ib-controller

                # bfg-repo-cleaner # removes passwords from git repo

                i3-battery-popup
                #nox
                nix-prefetch-git
                #gimp
                #imagemagick
                #ffmpeg-full # ffmpeg_7-full

                # nixpkgsLocal.pkgs.safeeyes
                # cmus

                # hubstaff

                # screen
                # abiword

                # pass
                # qtpass

                # nixfromnpm

                # My packages
                # dunsted-volume
                # randomize_background
                # kb-light
                # umsf
                # fix-github-https-repo

                # xmind
                # rubocop

                # all-hies.latest # all-hies.unstable.latest

                # hlint
                # auto-hie-wrapper # use all-hies.unstable.combined ..
                # nixpkgsMaster.pkgs.stack

                # (nixpkgsMaster.pkgs.haskell-language-server.override {
                #   supportedGhcVersions = [
                #     # "90"
                #     # "94"
                #     "910"
                #   ];
                # })

                #(writeShellScriptBin "tmuxx" "tmux attach || tmux new-session")

                (python3.withPackages (
                  ps: with ps; [
                    pynvim
                    #libtmux
                    # pip
                  ]
                ))

                # stack

                # haskellPackages.intero
                # stack2nix
                # cabal2nix

                # idris

                # sql linters parsers for vim
                # python36Packages.sqlparse
                # sqlint
                # pgFormatter
                # python36Packages.syncthing-gtk
                # arion

                # for vim
                # haskellPackages.hindent
                # haskellPackages.stylish-haskell
                # haskellPackages.brittany
                # (
                #   let
                #     # oldPkgs = import (fetchTarball https://nixos.org/channels/nixos-18.09/nixexprs.tar.xz) {};
                #     oldPkgs = import <nixos1803> {};
                #   in oldPkgs.haskellPackages.brittany
                # )
                # haskellPackages.Agda
                # steam

                # pgmodeler
                # obelisk.command

                #google-drive-ocamlfuse

                #dropbox-cli

                # ID kaart
                # chrome-token-signing
                # qdigidoc

                # kakoune

                # gfxtablet
                patchelf
                # write_stylus
                # xournal
                # texworks
                # lex

                # (
                #   texlive.combine {
                #     # tabularx is not available
                #     inherit (texlive) scheme-small cleveref latexmk bibtex algorithms cm-super
                #     csvsimple subfigure  glossaries collection-latexextra;
                #   }
                # )

                #ruby

                # gnome3.evolution

                # ib-tws
                # ib-controller
                #solargraph
                #ruby-lsp
                # fontforge
                # awscli2
                # amazon-ecs-cli
                # playonlinux

                sd

                # elmPackages.elm
                # elmPackages.elm-format

                # android-studio
                # tuxguitar
                # musescore
                # zoom
                # goldendict
                # go-ethereum
                #signal-desktop
                #niv
                # vym
                # FreeMind

                # update-module-name-purs

                # openbcigui
                # neuromore

                (writeShellScriptBin "ru" "${xkbcomp}/bin/xkbcomp -w ${./layouts/en_ru_swapped} $DISPLAY")
                (writeShellScriptBin "ua" "${xkbcomp}/bin/xkbcomp -w ${./layouts/en_ua_swapped} $DISPLAY")

                # nix profile install github:justinwoo/easy-purescript-nix#spago
                # (writeShellScriptBin "spago-migrate" "${easy-purescript-nix-automatic.spago}/bin/spago migrate")
                # purescript-overlay.spago-unstable
                # purescript-overlay.purs

                # npm install -g purs-tidy purs-backend-es spago@next
                #
                # purescript-overlay.purs-tidy-bin.purs-tidy-0_10_0
                # purescript-overlay.purs-tidy
                # purescript-overlay.purs-backend-es
                # easy-purescript-nix-automatic.purs
                # easy-purescript-nix-automatic.purty # find ./packages/client/src -name "*.purs" -exec purty --write {} \;

                #watchexec
                vlc
                # handbrake
                # nixpkgsVlc4.pkgs.vlc4
                #nixpkgsMaster.pkgs.yt-dlp
                # plasma5Packages.kdeconnect-kde

                # jsonls
                # js-debug-adapter
                # codelldb

                # blender

                # zoxide
                carapace # The best multi-shell completion engine for Nushell
                # cachix
                killall
                i3-volume

                dropbox
                elan
                just
                keepassxc
                typst
                typstyle
                uv
                # xmodmap
                # xxd

                xorg-server # provides Xephyr (needed for enter-testuser-wezterm)
              ];
            }
          )
        ];
      };
    };
}
