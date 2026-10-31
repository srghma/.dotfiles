GPG_BACKUP_DIR="$HOME/.dotfiles/secrets-ignored/gpg"
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

gpg-backup() {
  mkdir -p "$GPG_BACKUP_DIR" || return 1

  echo "[1/4] Exporting ownertrust..."
  gpg --export-ownertrust \
    > "$GPG_BACKUP_DIR/ownertrust.txt" || return 1

  echo "[2/4] Exporting public key..."
  gpg --armor --export "$USER_EMAIL" \
    > "$GPG_BACKUP_DIR/public.gpg" || return 1

  echo "[3/4] Exporting secret keys..."
  gpg --armor --export-secret-keys \
    > "$GPG_BACKUP_DIR/secret.gpg" || return 1

  echo "[4/4] Exporting all public keys..."
  gpg --armor --export \
    > "$GPG_BACKUP_DIR/public-keys.gpg" || return 1

  echo "Backup completed."
}

gpg-restore () {
  local RESET="\033[0m"
  local BOLD="\033[1m"
  local GREEN="\033[0;32m"
  local YELLOW="\033[0;33m"
  local BLUE="\033[0;34m"
  local RED="\033[0;31m"

  printf "${BOLD}${BLUE}🚀 Starting GPG restore...${RESET}\n"

  # 1. Fix ~/.gnupg permissions
  printf "${BLUE}🔒 Setting proper permissions on ~/.gnupg...${RESET}\n"
  chown -R "$(whoami)" ~/.gnupg/
  chmod 700 ~/.gnupg
  find ~/.gnupg -type f -exec chmod 600 {} +
  find ~/.gnupg -type d -exec chmod 700 {} +

  # 2. Import secret keys
  if [ -f "$GPG_BACKUP_DIR/secret.gpg" ]; then
    printf "${BLUE}🗝️  Importing secret key...${RESET}\n"
    gpg --batch --import "$GPG_BACKUP_DIR/secret.gpg" && \
      printf "${GREEN}✅ Secret key imported.${RESET}\n" || \
      printf "${RED}❌ Failed to import secret key.${RESET}\n"
  else
    printf "${YELLOW}⚠️  No secret.gpg found in $GPG_BACKUP_DIR${RESET}\n"
  fi

  # 3. Import public keys
  for pub_file in "$GPG_BACKUP_DIR/public-keys.gpg" "$GPG_BACKUP_DIR/public.gpg"; do
    if [ -f "$pub_file" ]; then
      printf "${BLUE}🌐 Importing public keys from $(basename "$pub_file")...${RESET}\n"
      gpg --batch --import "$pub_file"
    fi
  done

  # 4. Set ultimate trust on user key (using expect if present, fallback if not)
  printf "${BLUE}🛡️  Configuring ultimate trust for ${USER_EMAIL}...${RESET}\n"
  if command -v expect >/dev/null 2>&1; then
    printf "${BLUE}🤖 'expect' found. Automating interactive prompt...${RESET}\n"
    if expect -c "spawn gpg --edit-key $USER_EMAIL trust quit; send \"5\ry\r\"; expect eof"; then
      printf "${GREEN}✅ Ultimate trust set via expect!${RESET}\n"
    else
      printf "${RED}❌ expect automation failed.${RESET}\n"
    fi
  else
    printf "${YELLOW}⚠️  'expect' not installed. Falling back to native GPG trust...${RESET}\n"
    local fpr
    fpr=$(gpg --with-colons --list-keys "$USER_EMAIL" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
    if [ -n "$fpr" ]; then
      printf "${BLUE}🔑 Found fingerprint: ${fpr}${RESET}\n"
      if echo "${fpr}:6:" | gpg --import-ownertrust; then
        printf "${GREEN}✅ Ultimate trust set via native pipe!${RESET}\n"
      else
        printf "${RED}❌ Failed to set ultimate trust for ${fpr}${RESET}\n"
      fi
    else
      printf "${RED}❌ Key for '${USER_EMAIL}' not found in keyring!${RESET}\n"
    fi
  fi

  # 5. Restore full ownertrust database
  if [ -f "$GPG_BACKUP_DIR/ownertrust.txt" ]; then
    printf "${BLUE}📜 Restoring trust database from ownertrust.txt...${RESET}\n"
    if gpg --import-ownertrust "$GPG_BACKUP_DIR/ownertrust.txt"; then
      printf "${GREEN}✅ ownertrust.txt successfully imported!${RESET}\n"
    else
      printf "${RED}❌ Failed to import ownertrust.txt!${RESET}\n"
    fi
  else
    printf "${YELLOW}⚠️  ownertrust.txt not found, skipping.${RESET}\n"
  fi

  printf "${BOLD}${GREEN}🎉 GPG restore finished!${RESET}\n"
}
