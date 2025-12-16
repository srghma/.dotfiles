function tscfedit() {
  local files
  files=($(./node_modules/.bin/tsc --pretty false 2>&1 | grep ': error TS' | grep -o '^[^:(]\+' | sort -u))

  if (( ${#files[@]} )); then
    nvim "${files[@]}"
  else
    echo "✅ No TypeScript errors found — all good!"
  fi
}
