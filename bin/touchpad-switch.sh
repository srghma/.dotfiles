#!/bin/sh -eu
# touchpad-switch.sh
# TODO: merge with switch_touchpad
# Toggles the touchpad, sends notification, optionally prints debug info

TOUCHPAD_KEYWORD="Touchpad"
NOTIFY_ID=1234
TIMEOUT=2000
DEBUG=${DEBUG:-0}  # Set DEBUG=1 to print messages to stdout

notify() {
    msg="$1"
    notify-send -r "$NOTIFY_ID" -t "$TIMEOUT" "$msg"
    [ "$DEBUG" -eq 1 ] && echo "$msg"
}

# Get the touchpad line from xinput
TOUCHPAD_LINE=$(xinput list | grep "$TOUCHPAD_KEYWORD")

if [ -z "$TOUCHPAD_LINE" ]; then
    notify "Touchpad containing '$TOUCHPAD_KEYWORD' not found"
    exit 1
fi

# Extract ID
TOUCHPAD_ID=$(echo "$TOUCHPAD_LINE" | sed -n 's/.*id=\([0-9]\+\).*$/\1/p')

# Extract clean full name
TOUCHPAD_NAME=$(echo "$TOUCHPAD_LINE" | sed -E 's/^[^a-zA-Z0-9]*//; s/[[:space:]]+id=.*$//')

# Get current state (1 = enabled, 0 = disabled)
STATE=$(xinput list-props "$TOUCHPAD_ID" | grep "Device Enabled" | awk '{print $4}')

if [ "$STATE" -eq 1 ]; then
    xinput --disable "$TOUCHPAD_ID"
    notify "Touchpad disabled: $TOUCHPAD_NAME (ID: $TOUCHPAD_ID)"
else
    xinput --enable "$TOUCHPAD_ID"
    notify "Touchpad enabled: $TOUCHPAD_NAME (ID: $TOUCHPAD_ID)"
fi

# Explicitly return success
exit 0
