{ callPackage, fetchFromGitHub, readRevision, addIfdDeps }:

let
  src = fetchFromGitHub (readRevision ./revision.json);
  # src = /home/srghma/projects/dunsted-volume;

  drv = callPackage src {};
in
  #addIfdDeps [src] drv
  drv
