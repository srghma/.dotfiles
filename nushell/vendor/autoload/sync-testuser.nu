def sync-testuser [] {
    let test_home = "/home/testuser"
    let host_home = "/home/srghma"
    let copy_script = ($env.HOME | path join ".dotfiles/INSTALL/link_files__copy_safe_files_to_testuser.py")

    print $"(ansi cyan_bold)==> [1/4] Checking host security... (ansi reset)"
    let host_perm = (run-external "stat" "-c" "%a" $host_home | str trim)
    if $host_perm == "700" {
        print $"  (ansi green_bold)[OK](ansi reset) ($host_home) is protected \(700\)"
    } else {
        print $"  (ansi yellow_bold)[LOCK](ansi reset) ($host_home) was ($host_perm), locking to 700..."
        sudo chmod 700 $host_home
    }

    print $"\n(ansi cyan_bold)==> [2/4] Ensuring ($test_home) exists and is clean... (ansi reset)"
    if not ($test_home | path exists) {
        print $"  (ansi yellow_bold)[CREATE](ansi reset) Creating ($test_home)..."
        sudo mkdir -p $test_home
        sudo chown testuser:users $test_home
        sudo chmod 700 $test_home
    } else {
        print $"  (ansi green_bold)[OK](ansi reset) ($test_home) exists"
        # Wipe leftover/planted files from previous testuser sessions before copying
        print $"  (ansi yellow_bold)[CLEAN](ansi reset) Purging old files in ($test_home)..."
        sudo -u testuser -H find $test_home -mindepth 1 -delete
    }

    # Escaped parentheses: \(no root-in-user-home\)
    print $"\n(ansi cyan_bold)==> [3/4] Staging & copying dotfiles safely \(no root-in-user-home\)... (ansi reset)"
    let stage_dir = (run-external "mktemp" "-d" "/tmp/testuser-stage.XXXXXX" | str trim)

    try {
        # Run copy script into the staging dir
        python3 $copy_script $stage_dir

        # Sync wezterm plugins into staging dir
        let host_wezterm_plugins = ($host_home | path join ".local/share/wezterm/plugins")
        if ($host_wezterm_plugins | path exists) {
            mkdir ($stage_dir | path join ".local/share/wezterm")
            ^cp -rn $host_wezterm_plugins ($stage_dir | path join ".local/share/wezterm/")
        }

        # Allow testuser to read the staged files
        chmod -R 755 $stage_dir

        # Copy from staging into /home/testuser strictly AS testuser
        sudo -u testuser -H cp -r --no-dereference $"($stage_dir)/." $"($test_home)/"
        print $"  (ansi green_bold)[SYNC](ansi reset) Files safely synced as testuser."
    } catch { |err|
        sudo rm -rf $stage_dir
        error make {msg: $"Sync failed: ($err.msg? | default ($err | to text))"}
    }

    # Clean up staging dir
    sudo rm -rf $stage_dir

    print $"\n(ansi cyan_bold)==> [4/4] Verifying isolation... (ansi reset)"
    sudo chmod 700 $test_home
    print $"  (ansi green_bold)[OK](ansi reset) ($test_home) locked to 700."
    print $"\n(ansi green_bold)✨ Sync complete!(ansi reset) Staging verified."
}
