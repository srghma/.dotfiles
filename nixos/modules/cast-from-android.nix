# https://www.reddit.com/r/NixOS/comments/ztq0xn/nixos_and_miracast/
{ pkgs
, lib
, config
, ...
}:

{
  networking.firewall.allowedTCPPorts = [7236 7250];

  networking.firewall.allowedUDPPorts = [7236 5353];

  environment.systemPackages = with pkgs; [
    nixpkgsMaster.pkgs.gnome-network-displays
  ];
}
