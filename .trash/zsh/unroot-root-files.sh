unroot-root-files () {
  # * doesn't include hidden files by default
  # --from=root:root
  sudo chown -R `whoami`:users ./* && sudo chown -R `whoami`:users ./.[^.]*
}

