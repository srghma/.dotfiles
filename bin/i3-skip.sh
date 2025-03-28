#!/bin/sh

# nix profile install nixpkgs#xdotool
#
# Save current workspace (you can note the workspace number, or simply store it in a variable)
current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')

# Switch to a new workspace
i3-msg "workspace 11:11"
sleep 0.1

# Get the window ID of the Chrome window with "chatruletka" in the title
window_id=$(xdotool search --onlyvisible --class "chrome" | while read win; do
  title=$(xdotool getwindowname "$win")
  if echo "$title" | grep -iq "chatruletka"; then
    echo "$win"
    break
  fi
done)

# Focus on the found window (if any)
if [ -n "$window_id" ]; then
    # xdotool windowactivate "$window_id"
    # sleep 0.1
    xdotool keydown --window "$window_id" Up
    sleep 0.1
    xdotool keyup --window "$window_id" Up
    sleep 0.1
    i3-msg "workspace $current_workspace"
fi

# Perform actions, e.g.:
# xdotool mousemove 960 540 click 1
# sleep 0.1
#
# sleep 0.1

# Return to the original workspace
#
