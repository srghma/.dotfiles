#!/bin/sh -eu
# my-volume.sh - pactl volume control with notification

STEP="5%"
NOTIFY_ID="9911"
TIMEOUT="800"

SINK="@DEFAULT_SINK@"

get_vol() {
  pactl get-sink-volume "$SINK" | head -n1 | grep -o '[0-9]\+%' | head -n1
}

is_muted() {
  pactl get-sink-mute "$SINK" | awk '{print $2}'
}

notify() {
  notify-send -r "$NOTIFY_ID" -t "$TIMEOUT" "$1"
}

case "$1" in
  up)
    pactl set-sink-volume "$SINK" +"$STEP"
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  down)
    pactl set-sink-volume "$SINK" -"$STEP"
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  mute)
    pactl set-sink-mute "$SINK" toggle
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  *)
    echo "usage: $0 {up|down|mute}" >&2
    exit 1
    ;;
esac
