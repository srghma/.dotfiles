#!/bin/sh -eu
# my-volume.sh - volume control with notification

# ==============================================================================
# PROGRAM_TO_USE: "wpctl" | "pactl"
#
# NixOS requirements:
#   "wpctl": services.pipewire.enable = true;
#            (Native PipeWire / WirePlumber. No extra packages needed.)
#
#   "pactl": services.pipewire.pulse.enable = true;
#            (Or services.pulseaudio.enable = true;)
# ==============================================================================
PROGRAM_TO_USE="wpctl" # Change to "pactl" when pulse is enabled

STEP="5%"
NOTIFY_ID="9911"
TIMEOUT="800"

case "$PROGRAM_TO_USE" in
  wpctl)
    SINK="@DEFAULT_AUDIO_SINK@"
    vol_up()   { wpctl set-volume -l 1.0 "$SINK" "$STEP"+; }
    vol_down() { wpctl set-volume "$SINK" "$STEP"-; }
    vol_mute() { wpctl set-mute "$SINK" toggle; }
    get_vol()  { wpctl get-volume "$SINK" | awk '{print int($2 * 100) "%"}'; }
    is_muted() { wpctl get-volume "$SINK" | grep -q '\[MUTED\]' && echo "yes" || echo "no"; }
    ;;
  pactl)
    SINK="@DEFAULT_SINK@"
    vol_up()   { pactl set-sink-volume "$SINK" +"$STEP"; }
    vol_down() { pactl set-sink-volume "$SINK" -"$STEP"; }
    vol_mute() { pactl set-sink-mute "$SINK" toggle; }
    get_vol()  { pactl get-sink-volume "$SINK" | head -n1 | grep -o '[0-9]\+%' | head -n1; }
    is_muted() { pactl get-sink-mute "$SINK" | awk '{print $2}'; }
    ;;
  *)
    echo "Unknown PROGRAM_TO_USE: $PROGRAM_TO_USE (expected 'wpctl' or 'pactl')" >&2
    exit 1
    ;;
esac

notify() {
  notify-send -r "$NOTIFY_ID" -t "$TIMEOUT" "$1"
}

case "$1" in
  up)
    vol_up
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  down)
    vol_down
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  mute)
    vol_mute
    MUTE="$(is_muted)"
    VOL="$(get_vol)"
    [ "$MUTE" = "yes" ] && notify " Muted" || notify " Volume: $VOL"
    ;;
  *)
    echo "usage: $0 {up|down|mute}" >&2
    exit 1
    ;;
esac
