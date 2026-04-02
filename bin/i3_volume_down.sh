#!/usr/bin/env bash -euo pipefail

# read volume (e.g. "Volume: 0.42")
read -r _ vol _ < <(wpctl get-volume @DEFAULT_AUDIO_SINK@)

# convert to integer percent
vol=${vol#0.}          # strip "0."
vol=${vol:0:2}         # keep 2 digits max
vol=${vol:-0}          # fallback if empty

(( vol <= 5 )) && step=1 || step=5

exec i3-volume -n down "$step"

# # apply volume change
# wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-"
#
# # get updated volume
# read -r _ vol _ < <(wpctl get-volume @DEFAULT_AUDIO_SINK@)
# v=${vol#0.}
# v=${v:0:2}
# v=${v:-0}
#
# # build progress bar (10 segments)
# bars=$(( v / 10 ))
# bar=$(printf "%${bars}s" | tr ' ' '█')
# empty=$(printf "%$((10 - bars))s")
#
# # send notification (replace ID = 9999 to avoid spam stacking)
# dunstify -r 9999 -h int:value:"$v" "Volume: ${v}%" "${bar}${empty}"
