{
  pkgs,
  ...
}:
{
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xrandr}/bin/xrandr --setmonitor eDP-1-custom 2496/0x1600/0+64+0 eDP-1
  '';
}
