# ENCFS_BACKUP_DIR="$HOME/Encfs/Private"

# # https://gist.github.com/chrisroos/1205934

# encfs-backup () {
# }

# encfs-restore () {
#   # import secret key
#   encfs --import $GPG_BACKUP_DIR/secret.encfs

#   # all public keys
#   encfs --import $GPG_BACKUP_DIR/public-keys.encfs

#   # ultimately trust user key
#   expect -c "spawn encfs --edit-key $USER_EMAIL trust quit; send \"5\ry\r\"; expect eof"

#   # ownertrust
#   encfs --import-ownertrust $GPG_BACKUP_DIR/ownertrust.txt
# }

ask_for_password() {
  local password
  # local confirm_password

  # while true; do
  read -s "password?Enter password: " password
  # echo
  # read -s "confirm_password?Confirm password: " confirm_password
  # echo

  # if [[ "$password" == "$confirm_password" ]]; then
  #   break
  # else
  #   echo "Passwords do not match. Please try again."
  # fi
  # done

  echo "$password"
}

mydirectories=(
  "/home/srghma/.config/google-chrome-beta"
  "/home/srghma/.config/google-chrome-beta-for-srghma-chinese"
  # "/home/srghma/.ssh"
  # "/home/srghma/.aws"
  # "/home/srghma/projects/nuuz"
  # "/home/srghma/projects/vd-rails"
  # "/home/srghma/projects/zsh-nordicres"
  # "/home/srghma/.gnupg"
)

myfiles-encrypt() {
  # (cd "/home/srghma/projects/nuuz" && unroot-root-files)
  # (cd "/home/srghma/projects/vd-rails" && unroot-root-files)
  # (cd "/home/srghma/projects/zsh-nordicres" && unroot-root-files)

  read -s "password?Enter password: " password; echo
  # local password=$(ask_for_password)

  for dir in "${mydirectories[@]}"; do
    rm -f "$dir.encrypted.zip"
    rm -f "$dir.zip"
    zip -r -0 -P "$password" "$dir.zip" "$dir" &
  done

  wait

  echo "Encryption completed successfully."
}

myfiles-remove-originals() {
  for dir in "${mydirectories[@]}"; do
    rm -rf "$dir"
  done
  echo "Removal of original directories completed successfully."
}

myfiles-decrypt() {
  read -s "password?Enter password: " password; echo

  for dir in "${mydirectories[@]}"; do
    local encryptedDir="${dir}.zip"
    local decryptedDir="${dir}.decryptedDir"
    unzip -qq -P "$password" -d "$decryptedDir" "$encryptedDir" &
  done

  wait

  echo "Decryption completed successfully."

  for dir in "${mydirectories[@]}"; do
    local encryptedDir="${dir}.zip"
    local decryptedDir="${dir}.decryptedDir"
    echo mv "$decryptedDir$dir" "$dir"
    echo rm -rfd "$decryptedDir"
  done
}
