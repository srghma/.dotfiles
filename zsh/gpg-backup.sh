GPG_BACKUP_DIR="$HOME/.dotfiles/secrets/gpg"
USER_EMAIL="srghma@gmail.com"

# https://gist.github.com/chrisroos/1205934
#
# to create a key
#
# gpg --full-generate-key
# srghma@gmail
# gpg --list-key 432D0CEE62273527
# gpg --list-key $USER_EMAIL
# systemctl --user restart gpg-agent.service
# systemctl --user restart gpg-agent.socket
# gpg --list-secret-keys --keyid-format=long
# gpg --delete-keys 432D0CEE62273527
# gpg --delete-secret-keys 432D0CEE62273527
# gpg --edit-key $USER_EMAIL
# gpg --edit-key $USER_EMAIL trust quit
# key 1
# key 0
# adduid
# expire
# save

# pub   rsa2048 2017-04-27 [SC] [expires: 2024-05-06]
#       6C0CF37044DE7981088F9ADB432D0CEE62273527
# uid           [ultimate] Serhii Khoma (email for work2) <sergey@nr.com>
# uid           [ultimate] Sergey Homa (email for work) <sergey@nordicresults.com>
# uid           [ultimate] Sergey Homa <melgaardbjorn@gmail.com>
# uid           [ultimate] Sergey Homa <srghma@gmail.com>
# sub   rsa2048 2017-04-27 [E] [expires: 2024-05-06]

# pub   ed25519 2024-02-14 [SC] [expires: 2029-02-12]
#       FBC7001CD40D5AD2953100FA79CF9A1D25B1BB92
# uid           [ultimate] Serhii Khoma (email for work2, never used) <sergey@nr.com>
# uid           [ultimate] Serhii Khoma <srghma@gmail.com>
# uid           [ultimate] Serhii Khoma (email for work) <sergey@nordicresults.com>
# uid           [ultimate] Serhii Khoma (old email) <melgaardbjorn@gmail.com>
# sub   cv25519 2024-02-14 [E] [expires: 2029-02-12]

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
  gpg --import $GPG_BACKUP_DIR/public.gpg


  # ultimately trust user key
  expect -c "spawn gpg --edit-key $USER_EMAIL trust quit; send \"5\ry\r\"; expect eof"

  # ownertrust
  gpg --import-ownertrust $GPG_BACKUP_DIR/ownertrust.txt
}

