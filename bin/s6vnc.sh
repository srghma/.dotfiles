# https://github.com/santiagofdezg/linux-extend-screen/blob/master/README.md

gtf 2560 1600 60
xrandr --newmode "2560x1600_60.00"  348.16  2560 2752 3032 3504  1600 1601 1604 1656  -HSync +Vsync
xrandr --addmode HDMI-1 2560x1600_60.00
xrandr --output HDMI-1 --mode 2560x1600_60.00 --left-of eDP-1
x11vnc -clip 2560x1600+0+0

xrandr --output HDMI-1 --off
