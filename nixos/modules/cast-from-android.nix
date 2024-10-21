# https://www.reddit.com/r/NixOS/comments/ztq0xn/nixos_and_miracast/
{pkgs, ...}: {
  networking.firewall.allowedTCPPorts = [7236 7250];
  networking.firewall.allowedUDPPorts = [7236 5353];
  environment.systemPackages = with pkgs; [gnome-network-displays];
}
