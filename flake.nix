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

      nixpkgs = import inputs.nixpkgs nixosConfig;
      nixpkgsStable = import inputs.nixpkgsStable nixosConfig;
      # nixpkgsLocal = import inputs.nixpkgsLocal nixosConfig;
      nixpkgsMaster = import inputs.nixpkgsMaster nixosConfig;
    in
    # nixpkgsVlc4 = import inputs.nixpkgsVlc4 nixosConfig;
    # nixpkgsMyNeovimNightly = import inputs.nixpkgsMyNeovimNightly nixosConfig;
    {
      # devShells.${system}.default = nixpkgs.mkShell { };

      # packages.${system}.default =
      #   let
      #     pkgs = nixpkgs;
      #   in
      #   pkgs.python3.withPackages (python-pkgs: [
      #     python-pkgs.pip
      #     python-pkgs.setuptools
      #     python-pkgs.srt
      #     python-pkgs.openai-whisper
      #     # python-pkgs.vosk-api
      #   ]);

      packages.${system}.default =
        let
          pkgs = nixpkgs;
        in
        pkgs.conda.override {
          extraPkgs = [ pkgs.kdenlive ];
        };

      # packages.${system}.default =
      #   let
      #     pkgs = nixpkgs;
      #     pyver = "311";
      #     # cd ${builtins.toString ./.} && pip3 install -r requirements-freeze.txt && cd -
      #     prepare = ''
      #       pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
      #       pip3 install --upgrade pip setuptools wheel
      #       pip3 install --upgrade openai-whisper vosk
      #     '';
      #   in
      #   (pkgs.buildFHSEnv {
      #     name = "venv-py${pyver}";
      #     targetPkgs =
      #       pkgs:
      #       (
      #         (with pkgs; [
      #           # search: https://search.nixos.org/packages?&query=python+gssapi
      #           # pkgs."python${pyver}Packages".gssapi
      #           # heimdal.dev # for gssapi & krb5; See: https://github.com/NixOS/nixpkgs/issues/33103#issuecomment-796419851
      #           kdenlive
      #           python3
      #           python3Packages.pip
      #           python3Packages.virtualenv
      #           openssl
      #           zlib
      #           (lib.hiPrio gcc) # for native build wheel
      #         ])
      #         ++ pkgs.pythonManylinuxPackages.manylinux1
      #       );
      #     profile =
      #       ''
      #         export PROMPT_COMMAND='PS1="\[\033[01;32m\]venv-py${pyver}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ";unset PROMPT_COMMAND'
      #         python3 -m venv --system-site-packages ${builtins.toString ./.venv-py${pyver}}
      #         source ${builtins.toString ./.venv-py${pyver}/bin/activate}
      #       ''
      #       + prepare;
      #     runScript = "bash";
      #   });

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
              kb-light = pkgs.callPackage inputs.kb-light { };
              i3-battery-popup = pkgs.callPackage ./nixos/pkgs/i3-battery-popup { };
              switch_touchpad = pkgs.callPackage ./nixos/pkgs/switch_touchpad { };
              purescript-overlay = inputs.purescript-overlay.packages.${system};
              nix-alien-pkgs = inputs.nix-alien-pkgs.packages.${system};
            in
            {
              environment.systemPackages = with nixpkgs.pkgs; [
                # cd /home/srghma/projects/idris2-pack && nix profile install $(nix build)
                # cd /home/srghma/projects/Idris2 && nix profile install $(nix build)
                # inputs.Idris2.packages.${system}.default
                # inputs.idris2-pack.packages.${system}.default

                nix-alien-pkgs.nix-alien
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
                zed
                zip
                unzip
                htop
                silver-searcher
                ntfs3g
                alsa-utils

                okular

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

                # ranger
                joshuto
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

                universal-ctags
                # filezilla
                firefox
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

                # (python3.withPackages (
                #   ps: with ps; [
                #     pynvim
                #     libtmux
                #     # pip
                #   ]
                # ))

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
