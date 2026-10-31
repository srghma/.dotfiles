const SSH_BACKUP = "~/.dotfiles/secrets/ssh.tgz"
const SSH_DIR = "~/.ssh"

# Archives the ~/.ssh directory
export def ssh-backup [] {
    let backup_path = ($SSH_BACKUP | path expand)
    let src = ($SSH_DIR | path expand)

    if not ($src | path exists) {
        print $"(ansi red_bold)❌ Error:(ansi reset) Source directory (ansi cyan)($src)(ansi reset) does not exist."
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

    print $"(ansi bold)(ansi blue)🔑 Backing up SSH directory...(ansi reset)"
    print $"(ansi bold)📁 Source:(ansi reset)      (ansi cyan)($src)(ansi reset)"
    print $"(ansi bold)📦 Destination:(ansi reset) (ansi green)($backup_path)(ansi reset)"

    # Archive all files (avoids needing a subshell cd)
    let tar_res = (do { tar -C $src -zcf $backup_path . } | complete)

    if $tar_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Backup failed!(ansi reset)"
        if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
        return
    }

    # Restrict permissions on the backup archive (contains private keys)
    do { chmod 600 $backup_path } | complete

    print $"(ansi green_bold)✔ SSH backup completed successfully! (🔒 chmod 600)(ansi reset)"
}

# Restores the ~/.ssh directory from an archive and enforces strict permissions
export def ssh-restore [] {
    let backup_path = ($SSH_BACKUP | path expand)
    let target = ($SSH_DIR | path expand)

    if not ($backup_path | path exists) {
        print $"(ansi red_bold)❌ Error:(ansi reset) Backup archive (ansi cyan)($backup_path)(ansi reset) not found."
        return
    }

    print $"(ansi bold)(ansi blue)🚀 Restoring SSH directory...(ansi reset)"
    print $"(ansi bold)📦 Archive:(ansi reset)     (ansi cyan)($backup_path)(ansi reset)"
    print $"(ansi bold)📁 Destination:(ansi reset) (ansi green)($target)(ansi reset)"

    # Ensure target exists with directory 700 permissions
    if not ($target | path exists) {
        mkdir $target
    }
    do { chmod 700 $target } | complete

    # Extract archive
    let tar_res = (do { tar -xzf $backup_path -C $target } | complete)
    if $tar_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Restore failed!(ansi reset)"
        if ($tar_res.stderr | is-not-empty) { print $tar_res.stderr }
        return
    }

    # Enforce strict OpenSSH permissions to prevent "permissions are too open" errors
    print $"(ansi blue)🔒 Enforcing OpenSSH security permissions...(ansi reset)"
    do { chmod 700 $target } | complete
    do { ^find $target -type f -exec chmod 600 {} + } | complete

    # Set 644 on public keys (*.pub) and known_hosts if present
    let pub_keys = (glob $"($target)/*.pub")
    for pub_file in $pub_keys {
        do { chmod 644 $pub_file } | complete
    }

    let known_hosts = ($target | path join "known_hosts")
    if ($known_hosts | path exists) {
        do { chmod 644 $known_hosts } | complete
    }

    print $"(ansi green_bold)🎉 SSH directory restored successfully! (🔒 strict permissions enforced)(ansi reset)"
}
