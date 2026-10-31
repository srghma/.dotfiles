const SSH_DIR = "~/.ssh"

# Enforces strict permissions and ownership on ~/.ssh directory and its files
export def ssh-set-file-permissions [] {
    let ssh_path = ($SSH_DIR | path expand)

    if not ($ssh_path | path exists) {
        print $"(ansi red_bold)❌ Error:(ansi reset) SSH directory (ansi cyan)($ssh_path)(ansi reset) does not exist."
        return
    }

    let user = ($env.USER? | default (whoami | str trim))

    print $"(ansi bold)(ansi blue)🔒 Securing SSH permissions on(ansi reset) (ansi cyan)($ssh_path)(ansi reset)..."

    # 1. Fix ownership (user:wheel) and base directory permissions (700)
    print $"(ansi cyan)👤 Updating ownership to (ansi bold)($user):wheel(ansi reset)..."
    do { sudo chown $"($user):wheel" -R $ssh_path } | complete

    print $"(ansi cyan)📁 Setting directory permissions to 700...(ansi reset)"
    do { sudo chmod 700 -R $ssh_path } | complete

    # 2. Restrict all files to 600 by default (private keys, etc.)
    print $"(ansi cyan)🔑 Setting all SSH files to 600...(ansi reset)"
    do { sudo find $ssh_path -type f -exec chmod 600 {} + } | complete

    # 3. Public keys (*.pub): 644
    let pub_keys = (glob $"($ssh_path)/*.pub")
    if ($pub_keys | is-not-empty) {
        print $"(ansi cyan)🌐 Setting public keys (*.pub) to 644...(ansi reset)"
        for pub_file in $pub_keys {
            do { sudo chmod 644 $pub_file } | complete
        }
    }

    # 4. config and known_hosts: 644
    let config_file = ($ssh_path | path join "config")
    if ($config_file | path exists) {
        do { sudo chmod 644 $config_file } | complete
        print $"(ansi green)✔(ansi reset) Set (ansi bold)config(ansi reset) to 644"
    }

    let known_hosts = ($ssh_path | path join "known_hosts")
    if ($known_hosts | path exists) {
        do { sudo chmod 644 $known_hosts } | complete
        print $"(ansi green)✔(ansi reset) Set (ansi bold)known_hosts(ansi reset) to 644"
    }

    print $"(ansi bold)(ansi green)🎉 SSH file permissions successfully updated!(ansi reset)"
}

# Underscore alias for convenience
export alias ssh_set_file_permissions = ssh-set-file-permissions
