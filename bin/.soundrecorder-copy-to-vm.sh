#! /usr/bin/env nix-shell
#! nix-shell -i bash -I nixpkgs=channel:nixpkgs-master -p ffmpeg-full inotify-tools

# Directories
powerpoint_dir="$HOME/Downloads/powerpoint"
sound_recorder_dir="$HOME/.local/share/org.gnome.SoundRecorder"
voice_dir="$HOME/Downloads/voice"

# Ensure directories exist
if [[ ! -d "$powerpoint_dir" ]]; then
    echo "Directory $powerpoint_dir does not exist."
    exit 1
fi

if [[ ! -d "$sound_recorder_dir" ]]; then
    echo "Directory $sound_recorder_dir does not exist."
    exit 1
fi

if [[ ! -d "$voice_dir" ]]; then
    echo "Directory $voice_dir does not exist. Creating it..."
    mkdir -p "$voice_dir"
fi

# Function to convert .webm files to .mp4
convert_webm_to_mp4() {
    local file="$1"
    local output="${file%.webm}.mp4"
    if [ ! -f "$output" ] || [ ! -s "$output" ]; then
        ffmpeg -i "$file" "$output"
        echo "DONE $output"
    else
        echo "$output already exists, skipping..."
    fi
}

# Function to add extension and copy file
add_extension_and_copy() {
    local file="$1"
    local base_file=$(basename "$file")
    cp "$file" "$voice_dir/$base_file.mp3"
    echo "Copied $file to $voice_dir/$base_file.mp3"
}

# Function to remove the copied file
remove_copy() {
    local file="$1"
    local base_file=$(basename "$file")
    rm "$voice_dir/$base_file.mp3"
    echo "Removed $voice_dir/$base_file.mp3"
}

# Function to convert .flac files to .mp3
convert_flac_to_mp3() {
    local file="$1"
    local output="${file%.flac}.mp3"
    if [ ! -f "$output" ] || [ ! -s "$output" ]; then
        ffmpeg -i "$file" -q:a 0 "$output"
        echo "DONE $output"
    else
        echo "$output already exists, skipping..."
    fi
}

# Watch for changes in the directories
inotifywait -m "$powerpoint_dir" "$sound_recorder_dir" "$voice_dir" -e create -e delete |
    while read path action file; do
        if [[ "$path" == "$powerpoint_dir" && "$file" == *.webm ]]; then
            convert_webm_to_mp4 "$path/$file"
        elif [[ "$path" == "$sound_recorder_dir" ]]; then
            if [[ "$action" == "CREATE" ]]; then
                add_extension_and_copy "$path/$file"
            elif [[ "$action" == "DELETE" ]]; then
                remove_copy "$path/$file"
            fi
        elif [[ "$path" == "$voice_dir" && "$file" == *.flac ]]; then
            convert_flac_to_mp3 "$path/$file"
        fi
    done
