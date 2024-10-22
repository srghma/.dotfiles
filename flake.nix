# sudo nixos-rebuild switch --flake .
# sudo nixos-rebuild dry-build --flake .
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
    nixpkgsStable.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgsMaster.url = "github:NixOS/nixpkgs/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgsLocal.url = "path:/home/srghma/projects/nixpkgs";
    nixpkgsMyNeovimNightly.url = "github:srghma/nixpkgs/neovim2";
    nix-alien-pkgs.url = "github:thiagokokada/nix-alien";
    kb-light.url = "github:srghma/kb-light";
    kb-light.flake = false;
    dunsted-volume.url = "github:srghma/dunsted-volume";
    dunsted-volume.flake = false;
    fix-github-https-repo.url = "github:srghma/fix-github-https-repo";
    fix-github-https-repo.flake = false;
    image_optim.url = "github:toy/image_optim";
    image_optim.flake = false;
    easy-purescript-nix-automatic.url = "github:srghma/easy-purescript-nix-automatic";
    easy-purescript-nix-automatic.flake = false;
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
    purescript-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {self, ...} @ inputs: let
    system = "x86_64-linux";
    nixosConfig = {
      inherit system;
      config = {allowUnfree = true;};
    };

    nixpkgsStable = import inputs.nixpkgsStable nixosConfig;
    nixpkgsMaster = import inputs.nixpkgsMaster nixosConfig;
    nixpkgsLocal = import inputs.nixpkgsLocal nixosConfig;
    nixpkgsMyNeovimNightly = import inputs.nixpkgsMyNeovimNightly nixosConfig;
  in {
    nixosConfigurations.machine = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        {
          nixpkgs.overlays = [(_final: _prev: {inherit nixpkgsStable nixpkgsMaster;})];
        }
        ./nixos/root/default.nix
        ({pkgs, ...}: let
          dunsted-volume = pkgs.callPackage inputs.dunsted-volume {};
          kb-light = pkgs.callPackage inputs.kb-light {};
          i3-battery-popup =
            pkgs.callPackage ./nixos/pkgs/i3-battery-popup {};
          switch_touchpad =
            pkgs.callPackage ./nixos/pkgs/switch_touchpad {};

          purescript-overlay = inputs.purescript-overlay.packages.${system};
          nix-alien-pkgs = inputs.nix-alien-pkgs.packages.${system};
        in {
          environment.systemPackages = with pkgs; [
            nix-alien-pkgs.nix-alien
            brightnessctl

            keepassxc
            telegram-desktop
            nixpkgsMaster.pkgs.google-chrome
            # nixpkgsMaster.pkgs.chromium
            # chromium
            nixpkgsMaster.pkgs.libreoffice
            nixpkgsMaster.pkgs.inkscape
            zip
            unzip
            htop
            silver-searcher
            ntfs3g
            alsaUtils

            okular

            pavucontrol
            conky

            dunst
            copyq
            rofi
            pasystray
            scrot
            flameshot
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

            nixpkgsMaster.pkgs.ranger
            # nixpkgsMaster.pkgs.termite
            kitty
            # nixpkgsMyNeovimNightly.pkgs.neovim
            nixpkgsLocal.pkgs.neovim
            # nixpkgsStable.pkgs.neovim
            # nixpkgsMaster.pkgs.lunarvim
            # nixpkgsMaster.pkgs.lazygit
            nixpkgsMaster.pkgs.ripgrep
            lua-language-server
            nixpkgsMaster.pkgs.code-minimap
            # nixpkgsMaster.pkgs.alejandra
            nixpkgsMaster.pkgs.nixfmt-classic
            # nixpkgsMaster.pkgs.nixfmt-rfc-style
            nixpkgsMaster.pkgs.statix
            nixpkgsMaster.pkgs.selene
            nixpkgsMaster.pkgs.deadnix

            tmux
            vscode.fhs
            audacious
            # nix

            ## development
            git
            gitAndTools.diff-so-fancy
            gitAndTools.git-lfs
            gitAndTools.git-crypt
            meld

            # mplayer

            nodejs_latest
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

            ctags
            # filezilla
            firefox
            asciinema
            # tree
            # nixpkgsMaster.pkgs.youtube-dl
            tigervnc

            simplescreenrecorder
            # screencast
            # gtk-recordmydesktop
            # kdenlive
            # kazam

            # vagrant
            # nixpkgsMaster.pkgs.ib-tws
            # nixpkgsMaster.pkgs.ib-controller

            # fzf
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
            # nixpkgsMaster.pkgs.hubstaff

            # screen
            # abiword

            # pass
            # qtpass

            # nixfromnpm

            # My packages
            dunsted-volume
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

            (writeShellScriptBin "tmuxx"
              "${tmux}/bin/tmux attach || ${tmux}/bin/tmux new-session")

            # stack

            # haskellPackages.intero
            # stack2nix
            # cabal2nix

            # cd /home/srghma/projects/idris2-pack && nix-env --install $(nix build)
            # cd /home/srghma/projects/Idris2 && nix-env --install $(nix build)

            # idris

            # sql linters parsers for vim
            # python36Packages.sqlparse
            # sqlint
            # pgFormatter
            # python36Packages.syncthing-gtk
            # arion

            (python3.withPackages (ps:
              with ps; [
                pynvim
              ])) # for denite https://github.com/Shougo/denite.nvim/issues/456

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
            # fontforge
            # awscli2
            # amazon-ecs-cli
            # playonlinux

            nixpkgsMaster.pkgs.sd

            # elmPackages.elm
            # elmPackages.elm-format

            # android-studio
            fd
            # gitAndTools.gh
            # direnv
            # devenv
            # tuxguitar
            # musescore
            # zoom
            libnotify
            # nixpkgsMaster.pkgs.goldendict
            # go-ethereum
            nixpkgsMaster.pkgs.signal-desktop
            nixpkgsMaster.pkgs.niv
            # signal-desktop
            # vym
            # FreeMind

            # update-module-name-purs

            # openbcigui
            # neuromore

            # (writeShellScriptBin "spago-migrate"
            #   "${easy-purescript-nix-automatic.spago}/bin/spago migrate")

            (writeShellScriptBin "ru"
              "${xorg.xkbcomp}/bin/xkbcomp -w /home/srghma/.dotfiles/layouts/en_ru_swapped $DISPLAY")
            (writeShellScriptBin "ua"
              "${xorg.xkbcomp}/bin/xkbcomp -w /home/srghma/.dotfiles/layouts/en_ua_swapped $DISPLAY")

            # purescript-overlay.spago-unstable
            purescript-overlay.purs

            # npm install -g purs-tidy purs-backend-es spago@next
            #
            # purescript-overlay.purs-tidy-bin.purs-tidy-0_10_0
            # purescript-overlay.purs-tidy
            # purescript-overlay.purs-backend-es
            # easy-purescript-nix-automatic.purs
            # easy-purescript-nix-automatic.purty # find ./packages/client/src -name "*.purs" -exec purty --write {} \;

            nixpkgsMaster.pkgs.watchexec
            nixpkgsMaster.pkgs.vlc
            nixpkgsMaster.pkgs.yt-dlp
            nixpkgsMaster.pkgs.plasma5Packages.kdeconnect-kde

            # nixpkgsMaster.pkgs.jsonls
            # nixpkgsMaster.pkgs.js-debug-adapter
            # nixpkgsMaster.pkgs.codelldb

            # blender

            cachix
          ];
        })
      ];
    };
  };
}
