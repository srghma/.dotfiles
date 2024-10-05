{
  pkgs,
  fetchFromGitHub,
  readRevision,
  addIfdDeps,
}: let
  src = fetchFromGitHub (
    readRevision ./revision.json
  );
  # src = /home/srghma/projects/easy-purescript-nix-automatic;
  allPackages = import "${src}/default.nix" {inherit pkgs;};
in
  allPackages
  // {
    # spago = addIfdDeps [src] allPackages.spago;
    # purs      = addIfdDeps [src] allPackages.purs;
    # purty     = addIfdDeps [src] allPackages.purty;
  }
