{
  lib,
  stdenv,
  makeWrapper,
  libnotify,
  wireplumber, # provides wpctl
  # pulseaudio, # provides pactl (if used)
  gawk,
  gnugrep,
  coreutils,
}:

stdenv.mkDerivation rec {
  pname = "srghma-i3-volume";
  version = "0.1.0";

  name = "${pname}-${version}";

  src = ./srghma-i3-volume;

  unpackPhase = ":";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    install -v -D -m755 $src $out/bin/srghma-i3-volume
    wrapProgram "$out/bin/srghma-i3-volume" \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          wireplumber
          # pulseaudio
          gawk
          gnugrep
          coreutils
        ]
      }
  '';
}
