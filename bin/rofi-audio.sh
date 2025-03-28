#!/bin/sh

# Define the directory of the script
script_dir=$(dirname "$(realpath "$0")")
options_file="$script_dir/rofi-audio.txt"

# Read options from the file
options=$(<"$options_file")

# Let the user choose an option using rofi
chosen=$(echo -e "$options" | rofi -dmenu -p "Play")

# Remove leading and trailing whitespace from the chosen option
chosen=$(echo "$chosen" | xargs)

# If chosen is empty, exit the script
if [ -z "$chosen" ]; then
    exit 0
fi

# Create a hash of the chosen text to use as the filename
hashoftext=$(echo -n "$chosen" | sha256sum | cut -d' ' -f1)

# Define the path to the generated MP3 file
mp3_file="$HOME/Documents/rofi-audio/$hashoftext.mp3"

# Check if the file already exists, if not generate it using gtts-cli
if [ ! -f "$mp3_file" ]; then
    gtts-cli "$chosen" -l ru -o "$mp3_file"
fi

# Check if the chosen text is already in rofi-audio.txt, if not, append it
if ! grep -Fxq "$chosen" "$options_file"; then
    echo "$chosen" >> "$options_file"
fi

# Notify the user
notify-send "Playing: $chosen"

# Play the generated MP3 file using Audacious
audacious "$mp3_file"

# echo 'Как ваши дела?' | \
#   piper --model $HOME/.local/share/piper/ru_RU-denis-medium.onnx --output-raw | \
#   aplay -r 22050 -f S16_LE -t raw -
