#!/usr/bin/env bash

# Directory to save screenshots
SAVE_DIR="/home/srghma/Pictures"
mkdir -p "$SAVE_DIR"

# Generate filename based on timestamp
TIMESTAMP=$(date +'%Y-%m-%d-%I%p-%M-%S')
FILEPATH="$SAVE_DIR/${TIMESTAMP}-screenshot.png"

# Take the screenshot
# --monitor 0 captures the primary monitor
if scrot --monitor 0 "$FILEPATH"; then
    # Success notification
    notify-send "Screenshot Captured" "Saved to $FILEPATH" \
        -i camera-photo \
        -a "System" \
        --transient
else
    # Error notification
    notify-send "Screenshot Failed" "An error occurred while saving the file." \
        -u critical \
        -a "System"
    exit 1
fi
