{
  stdenv,
  autoPatchelfHook,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "odin4";
  version = "4";

  src = fetchzip {
    url = "https://github.com/Adrilaw/OdinV4/releases/download/v1.0/odin.zip";
    hash = "sha256-SoznK53UD/vblqeXBLRlkokaLJwhMZy7wqKufR0I8hI=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -m755 -D odin4 $out/bin/odin4
  '';
}
