# GPG_BACKUP_DIR="$HOME/.dotfiles/secrets/gpg"
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

module _gpg {
    use ../lib/log.nu [
        log-step, log-info, log-ok, log-warn, log-err, log-header, log-done
    ]

    const USER_EMAIL = "srghma@gmail.com"
    const BACKUP_DIR = "~/.dotfiles/secrets/gpg"
    const ARCHIVE_PATH = "~/.dotfiles/secrets/gpg.tgz"

    # --- Internal Helpers (not visible outside this module) ---

    def _gpg_export_file [
        step_msg: string,
        out_file: path,
        err_msg: string,
        action: closure
    ] {
        log-step $step_msg
        let res = (do $action | complete)
        if $res.exit_code != 0 {
            log-err $err_msg
            if ($res.stderr | is-not-empty) { print $res.stderr }
            return false
        }
        $res.stdout | save -f $out_file
        log-ok $"✔ Saved ($out_file)"
        true
    }

    def _gpg_import_file [
        file_path: path,
        label: string,
        --required
    ] {
        if not ($file_path | path exists) {
            if $required {
                log-warn $"⚠️  No ($label) found in ($file_path | path dirname)"
            }
            return
        }

        log-info $"🌐 Importing ($label) from ($file_path | path basename)..."
        let res = (do { gpg --batch --import $file_path } | complete)
        if $res.exit_code == 0 {
            log-ok $"✅ ($label) imported."
        } else {
            log-err $"❌ Failed to import ($label)."
            if ($res.stderr | is-not-empty) { print $res.stderr }
        }
    }

    # --- Public Commands ---

    # Backs up ownertrust, public keys, and secret keys into a .tgz archive
    export def gpg-backup [] {
        let backup_dir = ($BACKUP_DIR | path expand)
        let archive_path = ($ARCHIVE_PATH | path expand)

        mkdir $backup_dir
        log-header $"🚀 Starting GPG backup to (ansi cyan)($backup_dir)(ansi reset)"

        let tasks = [
            {
                step: "[1/4] 📜 Exporting ownertrust...",
                file: "ownertrust.txt",
                err: "❌ Failed to export ownertrust.",
                action: { gpg --export-ownertrust }
            },
            {
                step: $"[2/4] 🌐 Exporting public key for (ansi cyan_bold)($USER_EMAIL)(ansi reset)...",
                file: "public.gpg",
                err: $"❌ Failed to export public key for ($USER_EMAIL).",
                action: { gpg --armor --export $USER_EMAIL }
            },
            {
                step: "[3/4] 🗝️  Exporting secret keys...",
                file: "secret.gpg",
                err: "❌ Failed to export secret keys.",
                action: { gpg --armor --export-secret-keys }
            },
            {
                step: "[4/4] 📚 Exporting all public keys...",
                file: "public-keys.gpg",
                err: "❌ Failed to export all public keys.",
                action: { gpg --armor --export }
            }
        ]

        for task in $tasks {
            let out_file = ($backup_dir | path join $task.file)
            if not (_gpg_export_file $task.step $out_file $task.err $task.action) {
                return
            }
        }

        # Create tgz archive, secure permissions, and remove raw files
        log-step $"📦 Creating archive (ansi green)($archive_path)(ansi reset)..."
        let tar_res = (do { ^tar -C $backup_dir -zcf $archive_path . } | complete)
        if $tar_res.exit_code != 0 {
            log-err "❌ Failed to create tgz archive."
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }
        do { ^chmod 600 $archive_path } | complete
        rm -rf $backup_dir
        log-ok $"✔ Removed temporary directory ($backup_dir)"

        log-done "🎉 GPG backup completed successfully!"
    }

    # Restores GPG keys, permissions, trust database, and user key trust
    export def gpg-restore [] {
        let backup_dir = ($BACKUP_DIR | path expand)
        let archive_path = ($ARCHIVE_PATH | path expand)
        mut extracted_from_tar = false

        # Extract archive if tgz exists and dir does not
        if ($archive_path | path exists) and not ($backup_dir | path exists) {
            mkdir $backup_dir
            let tar_res = (do { ^tar -xzf $archive_path -C $backup_dir } | complete)
            if $tar_res.exit_code == 0 {
                $extracted_from_tar = true
            } else {
                log-err $"❌ Failed to extract ($archive_path)"
                return
            }
        }

        log-header $"🚀 Starting GPG restore from (ansi cyan)($backup_dir)(ansi reset)..."

        # 1. Fix ~/.gnupg permissions
        let gnupg_dir = ("~/.gnupg" | path expand)
        if ($gnupg_dir | path exists) {
            log-info "🔒 Setting proper permissions on ~/.gnupg..."
            let current_user = (whoami | str trim)
            do { ^chown -R $current_user $gnupg_dir } | complete
            do { ^chmod 700 $gnupg_dir } | complete
            do { ^find $gnupg_dir -type f -exec chmod 600 {} + } | complete
            do { ^find $gnupg_dir -type d -exec chmod 700 {} + } | complete
            log-ok "✔ Permissions updated on ~/.gnupg"
        }

        # 2. Import secret keys
        _gpg_import_file ($backup_dir | path join "secret.gpg") "secret.gpg" --required

        # 3. Import public keys
        for pub_name in ["public-keys.gpg", "public.gpg"] {
            _gpg_import_file ($backup_dir | path join $pub_name) $pub_name
        }

        # 4. Set ultimate trust on user key
        log-info $"🛡️  Configuring ultimate trust for (ansi cyan_bold)($USER_EMAIL)(ansi reset)..."
        if (which expect | is-not-empty) {
            log-info "🤖 'expect' found. Automating interactive prompt..."
            let expect_cmd = $"spawn gpg --edit-key ($USER_EMAIL) trust quit; send \"5\\ry\\r\"; expect eof"
            let exp_res = (do { ^expect -c $expect_cmd } | complete)
            if $exp_res.exit_code == 0 {
                log-ok "✅ Ultimate trust set via expect!"
            } else {
                log-err "❌ expect automation failed."
            }
        } else {
            log-warn "⚠️  'expect' not installed. Falling back to native GPG trust..."
            let gpg_list = (do { gpg --with-colons --list-keys $USER_EMAIL } | complete)
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
                log-info $"🔑 Found fingerprint: (ansi cyan_bold)($fpr)(ansi reset)"
                let trust_res = (do { $"($fpr):6:\n" | gpg --import-ownertrust } | complete)
                if $trust_res.exit_code == 0 {
                    log-ok "✅ Ultimate trust set via native pipe!"
                } else {
                    log-err $"❌ Failed to set ultimate trust for ($fpr)"
                }
            } else {
                log-err $"❌ Key for '($USER_EMAIL)' not found in keyring!"
            }
        }

        # 5. Restore full ownertrust database
        let ownertrust_file = ($backup_dir | path join "ownertrust.txt")
        if ($ownertrust_file | path exists) {
            log-info "📜 Restoring trust database from ownertrust.txt..."
            let ot_res = (do { gpg --import-ownertrust $ownertrust_file } | complete)
            if $ot_res.exit_code == 0 {
                log-ok "✅ ownertrust.txt successfully imported!"
            } else {
                log-err "❌ Failed to import ownertrust.txt!"
                if ($ot_res.stderr | is-not-empty) { print $ot_res.stderr }
            }
        } else {
            log-warn "⚠️  ownertrust.txt not found, skipping."
        }

        # Clean up temporary extracted folder if extracted from archive
        if $extracted_from_tar {
            rm -rf $backup_dir
        }

        log-done "🎉 GPG restore finished!"
    }
}

# Only expose the two commands in interactive shell sessions
use _gpg [gpg-backup, gpg-restore]
