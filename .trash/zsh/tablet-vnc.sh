# https://github.com/santiagofdezg/linux-extend-screen/blob/master/README.md

table-vnc-on () {
  local ip
  ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')

  if ! pgrep -x "x11vnc" > /dev/null; then
    x11vnc -rfbport 5901 -forever -shared -repeat -noxdamage -bg
    echo "x11vnc started."
    echo "In bVNC on your tablet, connect to: ${ip}:5901"
  else
    echo "x11vnc is already running. Connect to: ${ip}:5901"
  fi

  xset r on
}

table-vnc-off () {
  pkill -x x11vnc 2>/dev/null && echo "x11vnc stopped." || echo "x11vnc not running."
}
