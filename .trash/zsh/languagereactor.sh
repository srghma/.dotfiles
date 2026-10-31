unzip-languagereactor () {
  set -e
  dir=$(mktemp -d)
  cd "$HOME/Downloads"
  archive=$(fd --full-path --type f "lln.*.zip" | head -n 1)

  echo "$archive to $dir"

  unzip "$archive" -d "$dir"

  mv -vn "$dir"/media/* "$HOME/.local/share/Anki2/User 1/collection.media/"

  mv -v "$dir/items.csv" "$HOME/Downloads/"
}

