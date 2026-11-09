module _ssh {
    const SSH_BACKUP = "~/.dotfiles/secrets/ssh.tgz"
    const SSH_DIR = "~/.ssh"

    # --- Internal Helpers ---

    def _ssh_log_info [msg: string] {
        print $"(ansi blue)($msg)(ansi reset)"
    }

    def _ssh_log_header [msg: string] {
        print $"(ansi blue_bold)($msg)(ansi reset)"
    }

    def _ssh_log_err [msg: string] {
        print $"(ansi red_bold)($msg)(ansi reset)"
    }

    def _ssh_log_done [msg: string] {
        print $"(ansi green_bold)($msg)(ansi reset)"
    }

    def _ssh_enforce_permissions [target: path] {
        _ssh_log_info "🔒 Enforcing OpenSSH security permissions..."
        do { ^chmod 700 $target } | complete
        do { ^find $target -type f -exec chmod 600 {} + } | complete

        # Relax public keys and known_hosts to 644
        let pub_keys = (glob $"($target)/*.pub")
        for pub_file in $pub_keys {
            do { ^chmod 644 $pub_file } | complete
        }

        let known_hosts = ($target | path join "known_hosts")
        if ($known_hosts | path exists) {
            do { ^chmod 644 $known_hosts } | complete
        }
    }

    # --- Public Commands ---

    # Archives the ~/.ssh directory
    export def ssh-backup [] {
        let backup_path = ($SSH_BACKUP | path expand)
        let src = ($SSH_DIR | path expand)

        if not ($src | path exists) {
            _ssh_log_err $"❌ Error: Source directory ($src) does not exist."
            return
        }

        # Ensure parent directory of the backup exists
        let parent_dir = ($backup_path | path dirname)
        if not ($parent_dir | path exists) {
            mkdir $parent_dir
        }

        # Remove existing backup if present
        if ($backup_path | path exists) {
            rm -f $backup_path
        }

        _ssh_log_header "🔑 Backing up SSH directory..."
        print $"📁 Source:      (ansi cyan)($src)(ansi reset)"
        print $"📦 Destination: (ansi green)($backup_path)(ansi reset)"

        # Archive all files (avoids needing a subshell cd)
        let tar_res = (do { ^tar -C $src -zcf $backup_path . } | complete)
        if $tar_res.exit_code != 0 {
            _ssh_log_err "❌ Backup failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        # Restrict permissions on the backup archive (contains private keys)
        do { ^chmod 600 $backup_path } | complete

        _ssh_log_done "✔ SSH backup completed successfully! (🔒 chmod 600)"
    }

    # Restores the ~/.ssh directory from an archive and enforces strict permissions
    export def ssh-restore [] {
        let backup_path = ($SSH_BACKUP | path expand)
        let target = ($SSH_DIR | path expand)

        if not ($backup_path | path exists) {
            _ssh_log_err $"❌ Error: Backup archive ($backup_path) not found."
            return
        }

        _ssh_log_header "🚀 Restoring SSH directory..."
        print $"📦 Archive:     (ansi cyan)($backup_path)(ansi reset)"
        print $"📁 Destination: (ansi green)($target)(ansi reset)"

        # Ensure target directory exists with 700 permissions
        if not ($target | path exists) {
            mkdir $target
        }
        do { ^chmod 700 $target } | complete

        # Extract archive
        let tar_res = (do { ^tar -xzf $backup_path -C $target } | complete)
        if $tar_res.exit_code != 0 {
            _ssh_log_err "❌ Restore failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        _ssh_enforce_permissions $target
        _ssh_log_done "🎉 SSH directory restored successfully! (🔒 strict permissions enforced)"
    }
}

# Only expose the two commands in interactive shell sessions
use _ssh [ssh-backup, ssh-restore]
