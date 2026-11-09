{
  lib,
  stdenv,
  makeWrapper,
  libnotify,
  gawk,
  coreutils,
}:

stdenv.mkDerivation rec {
  pname = "srghma-i3-brightness";
  version = "0.1.0";

  name = "${pname}-${version}";

  src = ./srghma-i3-brightness;

  unpackPhase = ":";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -v -D -m755 $src $out/bin/srghma-i3-brightness
    wrapProgram "$out/bin/srghma-i3-brightness" \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          gawk
          coreutils
        ]
      }
  '';
}
