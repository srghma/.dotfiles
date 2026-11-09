json-beautify-inplace () {
  temp=$(mktemp --dry-run)
  echo "input = $1"
  echo "tmp = $temp"
  cp "$1" "$temp"
  jq . "$temp" > "$1"
}

json-uglify-inplace () {
  temp=$(mktemp --dry-run)
  echo "input = $1"
  echo "tmp = $temp"
  cp "$1" "$temp"
  jq -r tostring "$temp" > "$1"
}

# https://stackoverflow.com/questions/49808581/using-jq-how-can-i-split-a-very-large-json-file-into-multiple-files-each-a-spec
# jq -c 'to_entries[]' /tmp/tmp.JHtKYifOVx > ./zitools_cache.json
