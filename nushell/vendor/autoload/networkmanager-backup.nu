module _net_mgr {
    const DEFAULT_BACKUP = "~/.dotfiles/secrets/net-mgr.tgz"
    const DEFAULT_CONNECTIONS_DIR = "/etc/NetworkManager/system-connections"

    # --- Internal Helpers ---

    def _resolve_backup_path [file?: path] {
        ($file | default $DEFAULT_BACKUP) | path expand
    }

    def _log_header [msg: string] {
        print $"(ansi blue_bold)($msg)(ansi reset)"
    }

    def _log_step [msg: string] {
        print $"(ansi cyan)($msg)(ansi reset)"
    }

    def _log_info [msg: string] {
        print $"(ansi blue)($msg)(ansi reset)"
    }

    def _log_err [msg: string] {
        print $"(ansi red_bold)($msg)(ansi reset)"
    }

    def _log_done [msg: string] {
        print $"(ansi green_bold)($msg)(ansi reset)"
    }

    # --- Public Commands ---

    # Archives NetworkManager connection profiles
    export def net-mgr-backup [
        backup_file?: path,
        source_dir: path = "/etc/NetworkManager/system-connections"
    ] {
        let backup_path = (_resolve_backup_path $backup_file)

        if not ($source_dir | path exists) {
            _log_err $"❌ Error: Source directory ($source_dir) does not exist."
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

        _log_header "📶 Backing up NetworkManager connections..."
        print $"📁 Source:      (ansi cyan)($source_dir)(ansi reset)"
        print $"📦 Destination: (ansi green)($backup_path)(ansi reset)"

        # Archive all profiles
        let tar_res = (do { ^sudo tar -C $source_dir -zcf $backup_path . } | complete)
        if $tar_res.exit_code != 0 {
            _log_err "❌ Backup failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        # Fix ownership and permissions for the current user's dotfiles
        let current_user = ($env.USER? | default (do { ^id -un } | complete | get stdout | str trim))
        do { ^sudo chown $"($current_user):" $backup_path } | complete
        do { ^chmod 600 $backup_path } | complete

        _log_done "✔ NetworkManager backup completed successfully! (🔒 chmod 600)"
    }

    # Restores NetworkManager connection profiles from an archive
    export def net-mgr-restore [
        backup_file?: path,
        target_dir: path = "/etc/NetworkManager/system-connections"
    ] {
        let backup_path = (_resolve_backup_path $backup_file)

        if not ($backup_path | path exists) {
            _log_err $"❌ Error: Backup archive ($backup_path) not found."
            return
        }

        _log_header "🚀 Restoring NetworkManager connections..."
        print $"📦 Archive:     (ansi cyan)($backup_path)(ansi reset)"
        print $"📁 Destination: (ansi green)($target_dir)(ansi reset)"

        # Ensure destination directory exists
        let mkdir_res = (do { ^sudo mkdir -p $target_dir } | complete)
        if $mkdir_res.exit_code != 0 {
            _log_err $"❌ Failed to create target directory ($target_dir)."
            return
        }

        # Extract archive
        let tar_res = (do { ^sudo tar -xzf $backup_path -C $target_dir } | complete)
        if $tar_res.exit_code != 0 {
            _log_err "❌ Restore failed!"
            if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
            return
        }

        # NetworkManager requires root:root and 600 permissions on connection profiles
        _log_info "🔒 Securing permissions for NetworkManager profiles..."
        do { ^sudo chown -R root:root $target_dir } | complete
        do { ^sudo chmod 700 $target_dir } | complete
        do { ^sudo find $target_dir -type f -exec chmod 600 {} + } | complete

        # Reload NetworkManager connections if nmcli is installed
        if (which nmcli | is-not-empty) {
            _log_step "🔄 Reloading NetworkManager connections..."
            do { ^sudo nmcli connection reload } | complete
        }

        _log_done "🎉 NetworkManager connections restored successfully!"
    }
}

# Only expose the two commands in the interactive shell session
use _net_mgr [net-mgr-backup, net-mgr-restore]
