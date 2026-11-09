module _ssh_perms {
    const SSH_DIR = "~/.ssh"

    # --- Internal Helpers ---

    def _log_header [msg: string] {
        print $"(ansi blue_bold)($msg)(ansi reset)"
    }

    def _log_step [msg: string] {
        print $"(ansi cyan)($msg)(ansi reset)"
    }

    def _log_ok [msg: string] {
        print $"(ansi green)($msg)(ansi reset)"
    }

    def _log_err [msg: string] {
        print $"(ansi red_bold)($msg)(ansi reset)"
    }

    def _log_done [msg: string] {
        print $"(ansi green_bold)($msg)(ansi reset)"
    }

    # Enforces strict permissions and ownership on ~/.ssh directory and its files
    export def ssh-set-file-permissions [] {
        let ssh_path = ($SSH_DIR | path expand)

        if not ($ssh_path | path exists) {
            _log_err $"❌ Error: SSH directory ($ssh_path) does not exist."
            return
        }

        let user = ($env.USER? | default (do { ^id -un } | complete | get stdout | str trim))

        _log_header $"🔒 Securing SSH permissions on (ansi cyan)($ssh_path)(ansi reset)..."

        # 1. Fix ownership (user:wheel)
        _log_step $"👤 Updating ownership to (ansi cyan_bold)($user):wheel(ansi reset)..."
        do { ^sudo chown -R $"($user):wheel" $ssh_path } | complete

        # 2. Directory permissions: 700
        _log_step "📁 Setting directory permissions to 700..."
        do { ^sudo chmod 700 $ssh_path } | complete
        do { ^sudo find $ssh_path -type d -exec chmod 700 {} + } | complete

        # 3. Base file permissions: 600 (private keys, authorized_keys, etc.)
        _log_step "🔑 Setting all SSH files to 600..."
        do { ^sudo find $ssh_path -type f -exec chmod 600 {} + } | complete

        # 4. Public keys (*.pub): 644
        let pub_keys = (glob $"($ssh_path)/*.pub")
        if ($pub_keys | is-not-empty) {
            _log_step "🌐 Setting public keys (*.pub) to 644..."
            for pub_file in $pub_keys {
                do { ^sudo chmod 644 $pub_file } | complete
            }
        }

        # 5. Non-secret client files: 644
        for name in ["config", "known_hosts"] {
            let target_file = ($ssh_path | path join $name)
            if ($target_file | path exists) {
                do { ^sudo chmod 644 $target_file } | complete
                _log_ok $"✔ Set (ansi default_bold)($name)(ansi reset) to 644"
            }
        }

        _log_done "🎉 SSH file permissions successfully updated!"
    }

    # Underscore alias for convenience
    export alias ssh_set_file_permissions = ssh-set-file-permissions
}

# Only expose the command and its alias in the interactive shell session
use _ssh_perms [ssh-set-file-permissions, ssh_set_file_permissions]
