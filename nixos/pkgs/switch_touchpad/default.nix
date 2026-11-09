{
  lib,
  stdenv,
  makeWrapper,
  libnotify,
  xinput,
  gawk,
  gnused,
  gnugrep,
  coreutils,
}:

stdenv.mkDerivation rec {
  pname = "switch_touchpad";
  version = "0.1.0";

  name = "${pname}-${version}";
  src = ./switch_touchpad;

  unpackPhase = ":";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -v -D -m755 $src $out/bin/switch_touchpad
    wrapProgram "$out/bin/switch_touchpad" \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          xinput
          gawk
          gnused
          gnugrep
          coreutils
        ]
      }
  '';
}
