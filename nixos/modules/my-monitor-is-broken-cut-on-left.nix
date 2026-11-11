{
  pkgs,
  ...
}:
let
  monitor = "eDP-1";
  customName = "${monitor}-custom";

  # Native monitor resolution
  # (Run `xrandr --query | grep '*' | awk '{print $1}'` if you need to look it up)
  res = {
    width = 2560;
    height = 1600;
  };

  # Crop / inset percentages (0 - 100)
  crop = {
    left = 35; # 2.5% (represented as 25 / 1000 for precision)
    right = 0;
    top = 0;
    bottom = 0;
  };

  # Calculated offsets and viewport dimensions
  offsetX = (res.width * crop.left) / 1000;
  offsetY = (res.height * crop.top) / 1000;
  width = res.width - offsetX - ((res.width * crop.right) / 1000);
  height = res.height - offsetY - ((res.height * crop.bottom) / 1000);

  geometry = "${toString width}/0x${toString height}/0+${toString offsetX}+${toString offsetY}";
in
{
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xrandr}/bin/xrandr --setmonitor ${customName} ${geometry} ${monitor}
  '';
}
