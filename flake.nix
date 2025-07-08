# nix profile install nixpkgs\#yt-dlp --inputs-from ~/.dotfiles
#
# cd $HOME/.dotfiles && nix flake update
# cd $HOME/.dotfiles && nix flake update && sudo nixos-rebuild switch --flake ~/.dotfiles --verbose
# sudo nixos-rebuild dry-build --flake ~/.dotfiles --verbose
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
    nixpkgsStable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
    nixpkgsVlc4.url = "github:PerchunPak/nixpkgs/vlc4";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgsTelegramOld.url = "github:NixOS/nixpkgs/5df43628fdf08d642be8ba5b3625a6c70731c19c";
    # nixpkgsLocal.url = "git+file:/home/srghma/projects/nixpkgs";
    # nixpkgsMyNeovimNightly.url = "github:srghma/nixpkgs/neovim2";
    nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
    kb-light.url = "github:srghma/kb-light";
    kb-light.flake = false;
    # dunsted-volume.url = "github:srghma/dunsted-volume";
    # dunsted-volume.flake = false;
    fix-github-https-repo.url = "github:srghma/fix-github-https-repo";
    fix-github-https-repo.flake = false;
    image_optim.url = "github:toy/image_optim";
    image_optim.flake = false;
    easy-purescript-nix-automatic.url = "github:srghma/easy-purescript-nix-automatic";
    easy-purescript-nix-automatic.flake = false;
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
    purescript-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # Idris2.url = "git+file:/home/srghma/projects/Idris2";
    # Idris2.inputs.nixpkgs.follows = "nixpkgs";
    # idris2-pack.url = "git+file:/home/srghma/projects/idris2-pack";
    # idris2-pack.inputs.nixpkgs.follows = "nixpkgs";
    # sops-nix.url = "github:Mic92/sops-nix";
    # sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    zed.url = "github:zed-industries/zed";
    # zed.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      nixosConfig = {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # nixpkgsVlc4 = import inputs.nixpkgsVlc4 nixosConfig;
      # nixpkgsMyNeovimNightly = import inputs.nixpkgsMyNeovimNightly nixosConfig;
      # nixpkgsLocal = import inputs.nixpkgsLocal nixosConfig;
      nixpkgs = import inputs.nixpkgs nixosConfig;
      nixpkgsStable = import inputs.nixpkgsStable nixosConfig;
      nixpkgsMaster = import inputs.nixpkgsMaster nixosConfig;
      # nixpkgsTelegramOld = import inputs.nixpkgsTelegramOld nixosConfig;
    in
    {
      nixosConfigurations.machine = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # inputs.sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [ (_final: _prev: { inherit nixpkgsStable; }) ];
          }
          ./nixos/root/default.nix
          "${inputs.nixos-hardware}/lenovo/ideapad/16iah8"
          (
            { pkgs, ... }:
            let
              # dunsted-volume = pkgs.callPackage inputs.dunsted-volume { };
              # nix-alien-pkgs = inputs.nix-alien-pkgs.packages.${system};
              kb-light = pkgs.callPackage inputs.kb-light { };
              i3-battery-popup = pkgs.callPackage ./nixos/pkgs/i3-battery-popup { };
              switch_touchpad = pkgs.callPackage ./nixos/pkgs/switch_touchpad { };
              purescript-overlay = inputs.purescript-overlay.packages.${system};
            in
            {
              environment.systemPackages = with nixpkgs.pkgs; [
                # cd /home/srghma/projects/idris2-pack && nix profile install $(nix build)
                # cd /home/srghma/projects/Idris2 && nix profile install $(nix build)
                # inputs.Idris2.packages.${system}.default
                # inputs.idris2-pack.packages.${system}.default

                # nix-alien-pkgs.nix-alien
                brightnessctl

                keepassxc
                telegram-desktop
                nixpkgsMaster.pkgs.google-chrome
                code-cursor
                # chromium
                # chromium
                libreoffice
                inkscape
                # inputs.zed.packages.${system}.default
                zed-editor
                zip
                unzip
                htop
                silver-searcher
                ntfs3g
                alsa-utils

                kdePackages.okular

                pavucontrol
                conky

                dunst
                copyq
                yq-go # for tmux joshmedeski/tmux-nerd-font-window-name
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
                xclip
                atool
                wget
                gnupg
                thunderbird
                # psmisc
                # lxappearance

                ranger
                # joshuto
                # termite
                kitty
                # nixpkgsMyNeovimNightly.pkgs.neovim
                # nixpkgsLocal.pkgs.neovim
                neovim
                # lunarvim
                # lazygit
                ripgrep
                lua-language-server
                code-minimap
                # alejandra
                # nixfmt-classic
                nixfmt-rfc-style
                statix
                selene
                deadnix
                nixd

                vscode
                # vscode.fhs
                audacious
                # nix

                ## development
                git
                # gitAndTools.diff-so-fancy
                gitAndTools.gh
                gitAndTools.delta
                gitAndTools.git-lfs
                gitAndTools.git-crypt
                meld

                # mplayer

                # nodejs_latest
                nodejs_22
                # pnpm

                # netcat-openbsd # nc -U /var/run/acpid.socket
                lsof
                openssl

                # xorg.xbacklight
                acpilight

                unar
                unrar

                automake
                autoconf
                # autoconf
                gnumake
                gcc
                # inkscape

                poppler_utils
                docker-compose
                # mkpasswd

                universal-ctags
                # filezilla
                # firefox
                asciinema
                tree
                # youtube-dl
                tigervnc

                simplescreenrecorder
                # screencast
                # gtk-recordmydesktop
                # kdenlive
                # kazam

                # vagrant
                # ib-tws
                # ib-controller

                # bfg-repo-cleaner # removes passwords from git repo

                i3-battery-popup
                nox
                nix-prefetch-git
                gimp
                imagemagick
                ffmpeg-full # ffmpeg_7-full

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
                kb-light
                switch_touchpad
                # umsf
                # fix-github-https-repo

                # xmind
                jq
                rubocop

                # all-hies.latest # all-hies.unstable.latest

                # hlint
                # auto-hie-wrapper # use all-hies.unstable.combined ..
                stack

                (writeShellScriptBin "tmuxx" "tmux attach || tmux new-session")

                (python3.withPackages (
                  ps: with ps; [
                    pynvim
                    libtmux
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

                google-drive-ocamlfuse

                dropbox-cli

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

                ruby

                # gnome3.evolution

                # ib-tws
                # ib-controller
                solargraph
                ruby-lsp
                # fontforge
                # awscli2
                # amazon-ecs-cli
                # playonlinux

                sd

                # elmPackages.elm
                # elmPackages.elm-format

                # android-studio
                fd
                gitAndTools.gh
                # tuxguitar
                # musescore
                # zoom
                libnotify
                # goldendict
                # go-ethereum
                signal-desktop
                niv
                # signal-desktop
                # vym
                # FreeMind

                # update-module-name-purs

                # openbcigui
                # neuromore

                # nix profile install github:justinwoo/easy-purescript-nix#spago
                # (writeShellScriptBin "spago-migrate" "${easy-purescript-nix-automatic.spago}/bin/spago migrate")
                (writeShellScriptBin "ru" "${xorg.xkbcomp}/bin/xkbcomp -w /home/srghma/.dotfiles/layouts/en_ru_swapped $DISPLAY")
                (writeShellScriptBin "ua" "${xorg.xkbcomp}/bin/xkbcomp -w /home/srghma/.dotfiles/layouts/en_ua_swapped $DISPLAY")

                # purescript-overlay.spago-unstable
                purescript-overlay.purs

                # npm install -g purs-tidy purs-backend-es spago@next
                #
                # purescript-overlay.purs-tidy-bin.purs-tidy-0_10_0
                # purescript-overlay.purs-tidy
                # purescript-overlay.purs-backend-es
                # easy-purescript-nix-automatic.purs
                # easy-purescript-nix-automatic.purty # find ./packages/client/src -name "*.purs" -exec purty --write {} \;

                watchexec
                vlc
                handbrake
                # nixpkgsVlc4.pkgs.vlc4
                nixpkgsMaster.pkgs.yt-dlp
                plasma5Packages.kdeconnect-kde

                # jsonls
                # js-debug-adapter
                # codelldb

                # blender

                fzf
                zoxide
                cachix
                killall
                i3-volume
              ];
            }
          )
        ];
      };
    };
}
