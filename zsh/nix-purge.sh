# https://github.com/nixos-users/wiki/wiki/Garbage-collection
# https://github.com/NixOS/nixpkgs/blob/fb50cde71e3ffd149faca1a1762c245542a24875/nixos/modules/virtualisation/rkt.nix#L53
nix-purge () {
  # for link in /nix/var/nix/gcroots/auto/*
  # do
  #   rm -f $(readlink "$link")
  # done
  # # make all results of nix-build collected in next gc run
  # sudo rm -f /nix/var/nix/gcroots/auto/*

  # O_O is it safe?
  # sudo rm -f /boot/loader/entries/*

  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +1
  nix-env --delete-generations +1

  nix-store --gc
  nix-channel --update
  # nix-env -u --always

  nix-collect-garbage -d
  sudo nix-collect-garbage -d
}
