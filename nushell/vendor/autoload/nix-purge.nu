# https://github.com/nixos-users/wiki/wiki/Garbage-collection
# https://github.com/NixOS/nixpkgs/blob/fb50cde71e3ffd149faca1a1762c245542a24875/nixos/modules/virtualisation/rkt.nix#L53
def nix-purge [] {
  # for link in /nix/var/nix/gcroots/auto/*
  # do
  #   rm -f $(readlink "$link")
  # done
  # # make all results of nix-build collected in next gc run
  # sudo rm -f /nix/var/nix/gcroots/auto/*

  # O_O is it safe?
  # sudo rm -f /boot/loader/entries/*

  print $"(ansi yellow_bold)🗑️  Deleting old nix-env generations...(ansi reset)"
  sudo nix-env --delete-generations +1

  print $"(ansi cyan_bold)📜 Listing current nix-env generations...(ansi reset)"
  nix-env --list-generations

  print $"(ansi yellow_bold)⏱️  Wiping system profile history older than 14d...(ansi reset)"
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 14d

  print $"(ansi cyan_bold)📜 Listing system profile history...(ansi reset)"
  nix profile history --profile /nix/var/nix/profiles/system

  print $"(ansi purple_bold)🗄️  Running nix-store garbage collection...(ansi reset)"
  nix-store --gc

  print $"(ansi blue_bold)📦 Updating nix channels...(ansi reset)"
  nix-channel --update
  sudo nix-channel --update
  # nix-env -u --always

  print $"(ansi magenta_bold)💾 Deep garbage collection \(user and root)...(ansi reset)"
  nix-collect-garbage -d
  sudo nix-collect-garbage -d

  print $"(ansi green_bold)✨ Nix cleanup complete!(ansi reset)"
}
