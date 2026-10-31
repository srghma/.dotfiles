# GPG_BACKUP_DIR="$HOME/.dotfiles/secrets-ignored/gpg"
# USER_EMAIL="srghma@gmail.com"

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

# Backs up ownertrust, public keys, and secret keys
export def gpg-backup [
    email: string = "srghma@gmail.com",
    dir?: path
] {
    let backup_dir = ($dir | default ("~/.dotfiles/secrets-ignored/gpg" | path expand))

    mkdir $backup_dir
    print $"(ansi bold)(ansi blue)🚀 Starting GPG backup to(ansi reset) (ansi cyan)($backup_dir)(ansi reset)"

    # [1/4] Exporting ownertrust
    print $"(ansi cyan)[1/4] 📜 Exporting ownertrust...(ansi reset)"
    let ot_file = ($backup_dir | path join "ownertrust.txt")
    let ot_res = (do { gpg --export-ownertrust } | complete)
    if $ot_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to export ownertrust.(ansi reset)"
        return
    }
    $ot_res.stdout | save -f $ot_file
    print $"(ansi green)✔ Saved ($ot_file)(ansi reset)"

    # [2/4] Exporting public key
    print $"(ansi cyan)[2/4] 🌐 Exporting public key for(ansi reset) (ansi bold)($email)(ansi reset)..."
    let pub_file = ($backup_dir | path join "public.gpg")
    let pub_res = (do { gpg --armor --export $email } | complete)
    if $pub_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to export public key for ($email).(ansi reset)"
        return
    }
    $pub_res.stdout | save -f $pub_file
    print $"(ansi green)✔ Saved ($pub_file)(ansi reset)"

    # [3/4] Exporting secret keys
    print $"(ansi cyan)[3/4] 🗝️  Exporting secret keys...(ansi reset)"
    let sec_file = ($backup_dir | path join "secret.gpg")
    let sec_res = (do { gpg --armor --export-secret-keys } | complete)
    if $sec_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to export secret keys.(ansi reset)"
        return
    }
    $sec_res.stdout | save -f $sec_file
    print $"(ansi green)✔ Saved ($sec_file)(ansi reset)"

    # [4/4] Exporting all public keys
    print $"(ansi cyan)[4/4] 📚 Exporting all public keys...(ansi reset)"
    let all_pub_file = ($backup_dir | path join "public-keys.gpg")
    let all_pub_res = (do { gpg --armor --export } | complete)
    if $all_pub_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to export all public keys.(ansi reset)"
        return
    }
    $all_pub_res.stdout | save -f $all_pub_file
    print $"(ansi green)✔ Saved ($all_pub_file)(ansi reset)"

    print $"(ansi bold)(ansi green)🎉 GPG backup completed successfully!(ansi reset)"
}

# Restores GPG keys, permissions, trust database, and user key trust
export def gpg-restore [
    email: string = "srghma@gmail.com",
    dir?: path
] {
    let backup_dir = ($dir | default ("~/.dotfiles/secrets-ignored/gpg" | path expand))

    print $"(ansi bold)(ansi blue)🚀 Starting GPG restore from(ansi reset) (ansi cyan)($backup_dir)(ansi reset)..."

    # 1. Fix ~/.gnupg permissions
    let gnupg_dir = ("~/.gnupg" | path expand)
    if ($gnupg_dir | path exists) {
        print $"(ansi blue)🔒 Setting proper permissions on ~/.gnupg...(ansi reset)"
        let current_user = (whoami | str trim)
        do { ^chown -R $current_user $gnupg_dir } | complete
        do { ^chmod 700 $gnupg_dir } | complete
        do { ^find $gnupg_dir -type f -exec chmod 600 {} + } | complete
        do { ^find $gnupg_dir -type d -exec chmod 700 {} + } | complete
        print $"(ansi green)✔ Permissions updated on ~/.gnupg(ansi reset)"
    }

    # 2. Import secret keys
    let sec_file = ($backup_dir | path join "secret.gpg")
    if ($sec_file | path exists) {
        print $"(ansi blue)🗝️  Importing secret key...(ansi reset)"
        let sec_res = (do { gpg --batch --import $sec_file } | complete)
        if $sec_res.exit_code == 0 {
            print $"(ansi green)✅ Secret key imported.(ansi reset)"
        } else {
            print $"(ansi red)❌ Failed to import secret key.(ansi reset)"
            if ($sec_res.stderr | is-not-empty) { print $sec_res.stderr }
        }
    } else {
        print $"(ansi yellow)⚠️  No secret.gpg found in ($backup_dir)(ansi reset)"
    }

    # 3. Import public keys
    for pub_name in ["public-keys.gpg", "public.gpg"] {
        let pub_file = ($backup_dir | path join $pub_name)
        if ($pub_file | path exists) {
            print $"(ansi blue)🌐 Importing public keys from ($pub_name)...(ansi reset)"
            let pub_res = (do { gpg --batch --import $pub_file } | complete)
            if $pub_res.exit_code == 0 {
                print $"(ansi green)✅ ($pub_name) imported.(ansi reset)"
            } else {
                print $"(ansi red)❌ Failed to import ($pub_name).(ansi reset)"
            }
        }
    }

    # 4. Set ultimate trust on user key (using expect if present, fallback if not)
    print $"(ansi blue)🛡️  Configuring ultimate trust for(ansi reset) (ansi bold)($email)(ansi reset)..."
    if (which expect | is-not-empty) {
        print $"(ansi blue)🤖 'expect' found. Automating interactive prompt...(ansi reset)"
        let expect_cmd = $"spawn gpg --edit-key ($email) trust quit; send \"5\\ry\\r\"; expect eof"
        let exp_res = (do { ^expect -c $expect_cmd } | complete)
        if $exp_res.exit_code == 0 {
            print $"(ansi green)✅ Ultimate trust set via expect!(ansi reset)"
        } else {
            print $"(ansi red)❌ expect automation failed.(ansi reset)"
        }
    } else {
        print $"(ansi yellow)⚠️  'expect' not installed. Falling back to native GPG trust...(ansi reset)"
        let gpg_list = (do { gpg --with-colons --list-keys $email } | complete)
        let fpr = if $gpg_list.exit_code == 0 {
            let rows = ($gpg_list.stdout | lines | each { split row ':' } | where ($it | get 0?) == 'fpr')
            if ($rows | is-not-empty) {
                $rows | first | get 9? | default ""
            } else {
                ""
            }
        } else {
            ""
        }

        if ($fpr | is-not-empty) {
            print $"(ansi blue)🔑 Found fingerprint: (ansi bold)($fpr)(ansi reset)"
            let trust_res = (do { $"($fpr):6:\n" | gpg --import-ownertrust } | complete)
            if $trust_res.exit_code == 0 {
                print $"(ansi green)✅ Ultimate trust set via native pipe!(ansi reset)"
            } else {
                print $"(ansi red)❌ Failed to set ultimate trust for ($fpr)(ansi reset)"
            }
        } else {
            print $"(ansi red)❌ Key for '($email)' not found in keyring!(ansi reset)"
        }
    }

    # 5. Restore full ownertrust database
    let ownertrust_file = ($backup_dir | path join "ownertrust.txt")
    if ($ownertrust_file | path exists) {
        print $"(ansi blue)📜 Restoring trust database from ownertrust.txt...(ansi reset)"
        let ot_res = (do { gpg --import-ownertrust $ownertrust_file } | complete)
        if $ot_res.exit_code == 0 {
            print $"(ansi green)✅ ownertrust.txt successfully imported!(ansi reset)"
        } else {
            print $"(ansi red)❌ Failed to import ownertrust.txt!(ansi reset)"
        }
    } else {
        print $"(ansi yellow)⚠️  ownertrust.txt not found, skipping.(ansi reset)"
    }

    print $"(ansi bold)(ansi green)🎉 GPG restore finished!(ansi reset)"
}
