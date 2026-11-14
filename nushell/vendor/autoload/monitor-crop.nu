module _monitor {
    use ../lib/log.nu [log-info, log-header, log-err, log-done]

    # Applies a cropped custom virtual monitor over an output using per-mille (‰) margins
    export def monitor-crop [
        --left (-l): int = 40          # Inset per mille (‰) from left (35 = 3.5%)
        --right (-r): int = 0          # Inset per mille (‰) from right
        --top (-t): int = 0            # Inset per mille (‰) from top
        --bottom (-b): int = 0         # Inset per mille (‰) from bottom
        --monitor (-m): string = "eDP-1"
        --width (-W): int = 2560       # Native monitor width
        --height (-H): int = 1600      # Native monitor height
    ] {
        let custom_name = $"($monitor)-custom"

        # Math matching Nix integer division
        let offset_x = ($width * $left / 1000 | into int)
        let offset_y = ($height * $top / 1000 | into int)
        let custom_w = ($width - $offset_x - ($width * $right / 1000 | into int))
        let custom_h = ($height - $offset_y - ($height * $bottom / 1000 | into int))

        let geometry = $"($custom_w)/0x($custom_h)/0+($offset_x)+($offset_y)"

        log-header "🖥️  Configuring custom display geometry..."
        print $"🖥️  Monitor:    (ansi cyan)($monitor)(ansi reset) -> (ansi yellow)($custom_name)(ansi reset)"
        print $"📐 Native:     (ansi default)($width)x($height)(ansi reset)"
        print $"✂️  Crop \(‰\):    L: (ansi green)($left)(ansi reset) R: (ansi green)($right)(ansi reset) T: (ansi green)($top)(ansi reset) B: (ansi green)($bottom)(ansi reset)"
        print $"📏 Geometry:   (ansi magenta)($geometry)(ansi reset)"

        # Remove existing custom monitor if it was already applied
        do { ^xrandr --delmonitor $custom_name } | complete

        let set_res = (do { ^xrandr --setmonitor $custom_name $geometry $monitor } | complete)
        if $set_res.exit_code != 0 {
            log-err "❌ Failed to set custom monitor geometry!"
            if ($set_res.stderr | is-not-empty) { print $set_res.stderr }
            return
        }

        log-done $"✔ Successfully set ($custom_name)!"
        ^xrandr --listmonitors
    }

    # Removes the custom monitor overlay and resets to native
    export def monitor-reset [
        --monitor (-m): string = "eDP-1"
    ] {
        let custom_name = $"($monitor)-custom"
        log-header $"🔄 Resetting monitor ($monitor)..."

        let res = (do { ^xrandr --delmonitor $custom_name } | complete)
        if $res.exit_code != 0 {
            log-err $"❌ Monitor ($custom_name) is not currently active or failed to remove."
            return
        }

        log-done $"✔ Removed ($custom_name). Restored default view!"
        ^xrandr --listmonitors
    }
}

use _monitor [monitor-crop, monitor-reset]
