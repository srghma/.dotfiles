GPG_BACKUP_DIR="$HOME/.dotfiles/secrets/gpg"
USER_EMAIL="srghma@gmail.com"

# https://gist.github.com/chrisroos/1205934

gpg-backup () {
  mkdir -p $GPG_BACKUP_DIR

  # ownertrust
  gpg --export-ownertrust > $GPG_BACKUP_DIR/ownertrust.txt

  # public key
  gpg --armor --export "$USER_EMAIL" > $GPG_BACKUP_DIR/public.gpg

  # secret key
  gpg --armor --export-secret-keys  > $GPG_BACKUP_DIR/secret.gpg

  # all public keys
  gpg --armor --export > $GPG_BACKUP_DIR/public-keys.gpg
}

gpg-restore () {
  # To fix the " gpg: WARNING: unsafe permissions on homedir '/home/path/to/user/.gnupg' " error
  # Make sure that the .gnupg directory and its contents is accessibile by your user.
  chown -R $(whoami) ~/.gnupg/

  # Also correct the permissions and access rights on the directory
  chmod 600 ~/.gnupg/*
  chmod 700 ~/.gnupg

  # import secret key
  gpg --import $GPG_BACKUP_DIR/secret.gpg

  # all public keys
  gpg --import $GPG_BACKUP_DIR/public-keys.gpg

  # ultimately trust user key
  expect -c "spawn gpg --edit-key $USER_EMAIL trust quit; send \"5\ry\r\"; expect eof"

  # ownertrust
  gpg --import-ownertrust $GPG_BACKUP_DIR/ownertrust.txt
}

