# Archives NetworkManager connection profiles
export def net-mgr-backup [
    backup_file?: path,
    source_dir: path = "/etc/NetworkManager/system-connections"
] {
    let backup_path = ($backup_file | default ("~/.dotfiles/secrets/net-mgr.tgz" | path expand))

    if not ($source_dir | path exists) {
        print $"(ansi red_bold)❌ Error:(ansi reset) Source directory (ansi cyan)($source_dir)(ansi reset) does not exist."
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

    print $"(ansi bold)(ansi blue)📶 Backing up NetworkManager connections...(ansi reset)"
    print $"(ansi bold)📁 Source:(ansi reset)      (ansi cyan)($source_dir)(ansi reset)"
    print $"(ansi bold)📦 Destination:(ansi reset) (ansi green)($backup_path)(ansi reset)"

    # Archive all profiles (excluding hidden files)
    let tar_res = (do { sudo tar -C $source_dir -zcf $backup_path . } | complete)

    if $tar_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Backup failed!(ansi reset)"
        if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
        return
    }

    # Fix ownership and permissions for the current user's dotfiles
    let user = (whoami | str trim)
    do { sudo chown $"($user):" $backup_path } | complete
    do { chmod 600 $backup_path } | complete

    print $"(ansi green_bold)✔ NetworkManager backup completed successfully! (🔒 chmod 600)(ansi reset)"
}

# Restores NetworkManager connection profiles from an archive
export def net-mgr-restore [
    backup_file?: path,
    target_dir: path = "/etc/NetworkManager/system-connections"
] {
    let backup_path = ($backup_file | default ("~/.dotfiles/secrets/net-mgr.tgz" | path expand))

    if not ($backup_path | path exists) {
        print $"(ansi red_bold)❌ Error:(ansi reset) Backup archive (ansi cyan)($backup_path)(ansi reset) not found."
        return
    }

    print $"(ansi bold)(ansi blue)🚀 Restoring NetworkManager connections...(ansi reset)"
    print $"(ansi bold)📦 Archive:(ansi reset)     (ansi cyan)($backup_path)(ansi reset)"
    print $"(ansi bold)📁 Destination:(ansi reset) (ansi green)($target_dir)(ansi reset)"

    # Ensure destination exists
    let mkdir_res = (do { sudo mkdir -p $target_dir } | complete)
    if $mkdir_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Failed to create target directory ($target_dir).(ansi reset)"
        return
    }

    # Extract archive
    let tar_res = (do { sudo tar -xzf $backup_path -C $target_dir } | complete)
    if $tar_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Restore failed!(ansi reset)"
        if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
        return
    }

    # NetworkManager requires root:root and 600 permissions on connection profiles
    print $"(ansi blue)🔒 Securing permissions for NetworkManager profiles...(ansi reset)"
    do { sudo chown -R root:root $target_dir } | complete
    do { sudo chmod 700 $target_dir } | complete
    do { sudo find $target_dir -type f -exec chmod 600 {} + } | complete

    # Reload NetworkManager connections if nmcli is installed
    if (which nmcli | is-not-empty) {
        print $"(ansi cyan)🔄 Reloading NetworkManager connections...(ansi reset)"
        do { sudo nmcli connection reload } | complete
    }

    print $"(ansi green_bold)🎉 NetworkManager connections restored successfully!(ansi reset)"
}
