module _drmaci {
    use ../lib/log.nu [log-step, log-ok, log-info]

    # Instantaneously force-stops and removes all Docker containers
    export def drmaci [--fresh(-f)] {
        let ids = (docker ps -aq | lines | str trim | where ($it != ""))
        if ($ids | is-empty) {
            log-info "No containers to remove."
        } else {
            log-step $"🗑️  Force-removing ($ids | length) container\(s)..."
            # -f stops containers instantly without waiting for grace period
            # -v removes associated anonymous volumes
            let res = (do { docker rm -fv ...$ids } | complete)
            if $res.exit_code == 0 {
                log-ok "✔ All containers removed."
            } else {
                if ($res.stderr | is-not-empty) { print $res.stderr }
            }
        }

        if $fresh {
            log-step "🧹 Pruning unused networks and volumes..."
            do { docker network prune -f } | complete
            do { docker volume prune -f } | complete
            log-ok "✔ Docker network & volume state reset."
        }
    }
}

use _drmaci [drmaci]
