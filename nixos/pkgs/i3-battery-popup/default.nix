{ lib, stdenv, makeWrapper, libnotify, tk }:

stdenv.mkDerivation rec {
  pname = "i3-battery-popup";
  version = "0.1.0";

  name = "${pname}-${version}";

  src = ./i3-battery-popup;

  unpackPhase = ":";

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ libnotify tk ];

  installPhase = ''
    install -v -D -m755 $src $out/bin/i3-battery-popup
    wrapProgram "$out/bin/i3-battery-popup" \
      --prefix PATH : ${ lib.makeBinPath [libnotify tk] }
  '';
}
