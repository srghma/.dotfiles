module _ssh {
    use ../lib/log.nu [log-info, log-header, log-err, log-done]

    const SSH_BACKUP = "~/.dotfiles/secrets/ssh.tgz"
    const SSH_DIR = "~/.ssh"

    def _ssh_enforce_permissions [target: path] {
        log-info "🔒 Enforcing OpenSSH security permissions..."
        do { ^chmod 700 $target } | complete
        do { ^find $target -type f -exec chmod 600 {} + } | complete

        let pub_keys = (glob $"($target)/*.pub")
        for pub_file in $pub_keys {
            do { ^chmod 644 $pub_file } | complete
        }

        let known_hosts = ($target | path join "known_hosts")
        if ($known_hosts | path exists) {
            do { ^chmod 644 $known_hosts } | complete
        }
    }

    # Archives the ~/.ssh directory
    export def ssh-backup [] {
        let backup_path = ($SSH_BACKUP | path expand)
        let src = ($SSH_DIR | path expand)

        if not ($src | path exists) {
            log-err $"❌ Error: Source directory ($src) does not exist."
            return
        }

        let parent_dir = ($backup_path | path dirname)
        if not ($parent_dir | path exists) {
            mkdir $parent_dir
        }

        if ($backup_path | path exists) {
            rm -f $backup_path
        }

        log-header "🔑 Backing up SSH directory..."
        print $"📁 Source:      (ansi cyan)($src)(ansi reset)"
        print $"📦 Destination: (ansi green)($backup_path)(ansi reset)"

        let tar_res = (do { ^tar -C $src -zcf $backup_path . } | complete)
        if $tar_res.exit_code != 0 {
            log-err "❌ Backup failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        do { ^chmod 600 $backup_path } | complete
        log-done "✔ SSH backup completed successfully! (🔒 chmod 600)"
    }

    # Restores the ~/.ssh directory from an archive and enforces strict permissions
    export def ssh-restore [] {
        let backup_path = ($SSH_BACKUP | path expand)
        let target = ($SSH_DIR | path expand)

        if not ($backup_path | path exists) {
            log-err $"❌ Error: Backup archive ($backup_path) not found."
            return
        }

        log-header "🚀 Restoring SSH directory..."
        print $"📦 Archive:     (ansi cyan)($backup_path)(ansi reset)"
        print $"📁 Destination: (ansi green)($target)(ansi reset)"

        if not ($target | path exists) {
            mkdir $target
        }
        do { ^chmod 700 $target } | complete

        let tar_res = (do { ^tar -xzf $backup_path -C $target } | complete)
        if $tar_res.exit_code != 0 {
            log-err "❌ Restore failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        _ssh_enforce_permissions $target
        log-done "🎉 SSH directory restored successfully! (🔒 strict permissions enforced)"
    }
}

use _ssh [ssh-backup, ssh-restore]
