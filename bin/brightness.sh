#!/usr/bin/env bash

# get current brightness (float)
cur=$(sudo xbacklight -getf)

# determine step
if awk "BEGIN {exit !($cur <= 1)}"; then
    step=0.1
elif awk "BEGIN {exit !($cur <= 10)}"; then
    step=1
else
    step=10
fi

# apply adjustment
if [ "$1" = "up" ]; then
    sudo xbacklight -inc "$step"
else
    sudo xbacklight -dec "$step"
fi

# read updated brightness (raw float)
new=$(sudo xbacklight -getf)

# notify user
notify-send -t 800 "Brightness: ${new}%"
