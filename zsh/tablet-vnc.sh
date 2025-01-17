# https://github.com/santiagofdezg/linux-extend-screen/blob/master/README.md

table-vnc-on () {
  # Check if HDMI-1 is already connected and working
  if xrandr | grep "HDMI-1 connected"; then
    modeline=$(gtf 2560 1600 60 | grep Modeline | cut -d' ' -f4-)
    echo "Generated modeline: $modeline"
    eval xrandr --newmode "$modeline"
    # Add the mode to HDMI-1 output
    xrandr --addmode HDMI-1 2560x1600_60.00
    # Set HDMI-1 output mode and position it relative to eDP-1
    xrandr --output HDMI-1 --mode 2560x1600_60.00 --left-of eDP-1
    echo "HDMI-1 configured with resolution 2560x1600 and positioned left of eDP-1."
  else
    echo "HDMI-1 is not connected or not available."
  fi

  # Check if x11vnc is not already running
  if ! pgrep -x "x11vnc" > /dev/null; then
    # Start x11vnc with clip to match screen resolution
    x11vnc -clip 2560x1600+0+0 -rfbport 5901 &
    echo "x11vnc started on port 5901 with clipping."
  else
    echo "x11vnc is already running."
  fi

  # Enable repeat keys
  xset r on
  echo "Key repeat enabled."
}

table-vnc-off () {
  # Kill the x11vnc process if it is running
  if pgrep -x "x11vnc" > /dev/null; then
    pkill -x x11vnc
    echo "x11vnc process stopped."
  else
    echo "x11vnc is not running."
  fi

  # Revert HDMI-1 and restore primary screen setup
  if xrandr | grep "HDMI-1 connected"; then
    xrandr --output HDMI-1 --off
    echo "HDMI-1 output turned off."
  else
    echo "HDMI-1 is not connected or already off."
  fi
}
