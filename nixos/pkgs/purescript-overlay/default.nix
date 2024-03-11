{ pkgs, fetchFromGitHub, ... }:

let
  readRevision = path:
    let
      revData = builtins.fromJSON (builtins.readFile path);
      url     = revData.url;

      m       = builtins.match "https?://.*/(.*)/(.*)" url;
      owner   = builtins.elemAt m 0;
      repo    = builtins.elemAt m 1;
    in { inherit owner repo; inherit (revData) rev sha256; };

  src = fetchFromGitHub (
    readRevision ./revision.json
  );

  # arionSrc = import src { inherit pkgs; };
  pkg = import src;

  drv = pkg.packages;
in
  # src
  drv.x86_64-linux
