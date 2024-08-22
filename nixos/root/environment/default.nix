{ pkgs, ... }:

with pkgs;

let
  systemPackages = [
    brightnessctl

    nixpkgsUnstable.pkgs.keepassxc
    nixpkgsUnstable.pkgs.telegram-desktop
    nixpkgsMaster.pkgs.google-chrome
    # nixpkgsMaster.pkgs.chromium
    # nixpkgsUnstable.pkgs.chromium
    nixpkgsMaster.pkgs.libreoffice
    nixpkgsMaster.pkgs.inkscape
    nixpkgsUnstable.pkgs.zip
    nixpkgsUnstable.pkgs.unzip
    nixpkgsUnstable.pkgs.htop
    nixpkgsUnstable.pkgs.silver-searcher
    nixpkgsUnstable.pkgs.ntfs3g
    nixpkgsUnstable.pkgs.alsaUtils

    nixpkgsUnstable.pkgs.okular

    nixpkgsUnstable.pkgs.pavucontrol
    nixpkgsUnstable.pkgs.conky

    nixpkgsUnstable.pkgs.dunst
    nixpkgsUnstable.pkgs.copyq
    nixpkgsUnstable.pkgs.rofi
    nixpkgsUnstable.pkgs.pasystray
    nixpkgsUnstable.pkgs.scrot
    nixpkgsUnstable.pkgs.flameshot
    # anki
    # nixpkgsLocal.pkgs.anki-bin
    nixpkgsUnstable.pkgs.xarchiver
    # nixpkgsLocal.pkgs.ngrok

    ## misc
    nixpkgsUnstable.pkgs.transmission-gtk
    nixpkgsUnstable.pkgs.feh
    nixpkgsUnstable.pkgs.mpv
    nixpkgsUnstable.pkgs.xclip
    nixpkgsUnstable.pkgs.atool
    nixpkgsUnstable.pkgs.wget
    nixpkgsUnstable.pkgs.gnupg
    nixpkgsUnstable.pkgs.thunderbird
    # psmisc
    # lxappearance

    nixpkgsMaster.pkgs.ranger
    # nixpkgsMaster.pkgs.termite
    nixpkgsUnstable.pkgs.kitty
    nixpkgsUnstable.pkgs.neovim
    nixpkgsUnstable.pkgs.tmux
    nixpkgsUnstable.pkgs.vscode
    # nixpkgsUnstable.pkgs.nix

    ## development
    git
    gitAndTools.diff-so-fancy
    gitAndTools.git-lfs
    gitAndTools.git-crypt
    meld

    # nixpkgsUnstable.pkgs.mplayer

    nixpkgsUnstable.pkgs.nodejs_latest
    # nixpkgsUnstable.pkgs.pnpm

    # netcat-openbsd # nc -U /var/run/acpid.socket
    lsof
    openssl

    # xorg.xbacklight
    acpilight

    unar
    unrar

    automake
    autoconf
    # nixpkgsUnstable.autoconf
    gnumake
    gcc
    # nixpkgsUnstable.pkgs.inkscape

    nixpkgsUnstable.pkgs.poppler_utils
    nixpkgsUnstable.pkgs.docker-compose
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
    # nixpkgsUnstable.pkgs.kdenlive
    # kazam

    # vagrant
    # nixpkgsMaster.pkgs.ib-tws
    # nixpkgsMaster.pkgs.ib-controller

    # fzf
    # bfg-repo-cleaner # removes passwords from git repo

    mypkgs.i3-battery-popup
    nixpkgsUnstable.pkgs.nox
    nix-prefetch-git
    gimp
    nixpkgsUnstable.pkgs.imagemagick
    nixpkgsUnstable.pkgs.ffmpeg-full # pkgs.ffmpeg_7-full

    # nixpkgsLocal.pkgs.safeeyes
    # cmus

    # mypkgs.hubstaff
    # nixpkgsMaster.pkgs.hubstaff

    # screen
    # abiword

    # pass
    # qtpass

    # mypkgs.nixfromnpm

    # My packages
    mypkgs.dunsted-volume
    # mypkgs.randomize_background
    # mypkgs.kb-light
    mypkgs.switch_touchpad
    mypkgs.tmuxx
    # mypkgs.umsf
    # mypkgs.fix-github-https-repo

    # xmind
    jq
    nixpkgsUnstable.pkgs.rubocop

    # mypkgs.all-hies.latest # mypkgs.all-hies.unstable.latest

    # nixpkgsUnstable.pkgs.hlint
    # mypkgs.auto-hie-wrapper # use mypkgs.all-hies.unstable.combined ..
    nixpkgsUnstable.pkgs.stack
    # stack

    # haskellPackages.intero
    # stack2nix
    # nixpkgsUnstable.pkgs.cabal2nix

    # nixpkgsUnstable.pkgs.idris

    # sql linters parsers for vim
    # python36Packages.sqlparse
    # sqlint
    # mypkgs.pgFormatter
    # python36Packages.syncthing-gtk
    # mypkgs.arion

    (nixpkgsUnstable.python3.withPackages (ps: with ps; [ pynvim ])) # for denite https://github.com/Shougo/denite.nvim/issues/456

    # for vim
    # nixpkgsUnstable.haskellPackages.hindent
    # nixpkgsUnstable.haskellPackages.stylish-haskell
    # nixpkgsUnstable.haskellPackages.brittany
    # (
    #   let
    #     # oldPkgs = import (fetchTarball https://nixos.org/channels/nixos-18.09/nixexprs.tar.xz) {};
    #     oldPkgs = import <nixos1803> {};
    #   in oldPkgs.haskellPackages.brittany
    # )
    # haskellPackages.Agda
    # nixpkgsUnstable.pkgs.steam

    # mypkgs.pgmodeler
    # mypkgs.obelisk.command

    # Research
    # nixpkgsUnstable.pkgs.zotero
    google-drive-ocamlfuse

    dropbox-cli

    # ID kaart
    # nixpkgsUnstable.pkgs.chrome-token-signing
    # nixpkgsUnstable.pkgs.qdigidoc

    # nixpkgsUnstable.pkgs.kakoune

    # nixpkgsUnstable.pkgs.gfxtablet
    nixpkgsUnstable.pkgs.patchelf
    # nixpkgsUnstable.pkgs.write_stylus
    # xournal
    # nixpkgsUnstable.pkgs.texworks
    # nixpkgsUnstable.pkgs.lex

    # (
    #   texlive.combine {
    #     # tabularx is not available
    #     inherit (pkgs.texlive) scheme-small cleveref latexmk bibtex algorithms cm-super
    #     csvsimple subfigure  glossaries collection-latexextra;
    #   }
    # )

    ruby

    # nixpkgsUnstable.pkgs.gnome3.evolution

    # nixpkgsUnstable.pkgs.ib-tws
    # nixpkgsUnstable.pkgs.ib-controller
    nixpkgsUnstable.pkgs.solargraph
    # nixpkgsUnstable.pkgs.fontforge
    # nixpkgsUnstable.pkgs.awscli2
    # nixpkgsUnstable.pkgs.amazon-ecs-cli
    # nixpkgsUnstable.pkgs.playonlinux

    nixpkgsMaster.pkgs.sd

    # nixpkgsUnstable.pkgs.elmPackages.elm
    # nixpkgsUnstable.pkgs.elmPackages.elm-format

    # nixpkgsUnstable.pkgs.android-studio
    nixpkgsUnstable.pkgs.fd
    # nixpkgsUnstable.pkgs.gitAndTools.gh
    # nixpkgsUnstable.pkgs.direnv
    # nixpkgsUnstable.pkgs.devenv
    #nixpkgsUnstable.pkgs.tuxguitar
    # nixpkgsUnstable.pkgs.musescore
    # nixpkgsUnstable.pkgs.zoom
    nixpkgsUnstable.pkgs.libnotify
    # nixpkgsMaster.pkgs.goldendict
    # nixpkgsUnstable.pkgs.go-ethereum
    nixpkgsMaster.pkgs.signal-desktop
    nixpkgsMaster.pkgs.niv
    # mypkgs.signal-desktop
    # nixpkgsUnstable.pkgs.vym
    # nixpkgsUnstable.pkgs.FreeMind

    # mypkgs.update-module-name-purs

    # mypkgs.openbcigui
    # mypkgs.neuromore

    (pkgs.writeShellScriptBin "spago-migrate" "${mypkgs.easy-purescript-nix-automatic.spago}/bin/spago migrate")
    mypkgs.purescript-overlay.spago-unstable
    mypkgs.purescript-overlay.purs

    # mypkgs.purescript-overlay.purs-tidy-bin.purs-tidy-0_10_0
    mypkgs.purescript-overlay.purs-tidy
    mypkgs.purescript-overlay.purs-backend-es
    # mypkgs.easy-purescript-nix-automatic.purs
    # mypkgs.easy-purescript-nix-automatic.purty # find ./packages/client/src -name "*.purs" -exec purty --write {} \;

    nixpkgsMaster.pkgs.watchexec
    nixpkgsMaster.pkgs.vlc
    nixpkgsMaster.pkgs.yt-dlp
    nixpkgsMaster.pkgs.kdeconnect

    nixpkgsMaster.pkgs.blender

    (import (fetchTarball https://github.com/cachix/devenv/archive/v0.6.2.tar.gz)).default
  ];
in
{
  systemPackages = systemPackages;
  # systemPackages = [ neovim ];

  variables = {
    EDITOR = "nvim";
  };

  etc."resolvconf.conf".text = ''
    name_servers='8.8.8.8'
  '';
}
