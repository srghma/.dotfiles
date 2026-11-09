{
  lib,
  stdenv,
  makeWrapper,
  libnotify,
  scrot,
  coreutils,
}:

stdenv.mkDerivation rec {
  pname = "srghma-i3-screenshot";
  version = "0.1.0";

  name = "${pname}-${version}";

  src = ./srghma-i3-screenshot;

  unpackPhase = ":";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -v -D -m755 $src $out/bin/srghma-i3-screenshot
    wrapProgram "$out/bin/srghma-i3-screenshot" \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          scrot
          coreutils
        ]
      }
  '';
}
