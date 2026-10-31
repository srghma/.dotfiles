# Converts an SSH Git URL (or SCP-style URL) to an HTTPS GitLab/GitHub URL
export def git_ssh_to_https_url [url: string]: string -> string {
    let clean = ($url | str trim | str replace -r '\.git$' '')

    if ($clean | is-empty) {
        return ""
    }

    # Already HTTP/HTTPS
    if ($clean | str starts-with "http://") or ($clean | str starts-with "https://") {
        return ($clean | str replace -r '^http://' 'https://')
    }

    # Remove ssh:// and/or git@ prefixes
    let without_proto = ($clean
        | str replace -r '^ssh://' ''
        | str replace -r '^git@' '')

    # Convert the first ':' (host separator or port separator) to '/'
    let normalized = ($without_proto | str replace ':' '/')
    let parts = ($normalized | split row '/')

    # Extract hostname (stripping port if still attached)
    let raw_host = ($parts | first)
    let host = ($raw_host | split row ':' | first)

    # Check if the segment immediately following the host is a numeric port (e.g. :2222/)
    let remaining = ($parts | skip 1)
    let path_parts = if (($remaining | first? | default "") =~ '^\d+$') {
        $remaining | skip 1
    } else {
        $remaining
    }

    let path = ($path_parts | str join '/')
    $"https://($host)/($path)"
}

# Alias supporting Nushell standard kebab-case naming
export alias git-ssh-to-https-url = git_ssh_to_https_url

# Opens the GitLab Merge Request creation page for the current branch
export def gpo-open [] {
    # 1. Detect current branch
    let branch_res = (do { git rev-parse --abbrev-ref HEAD } | complete)
    if $branch_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Error:(ansi reset) Not inside a git repository or unable to detect branch."
        return
    }
    let branch = ($branch_res.stdout | str trim)

    # 2. Get remote URL (prefer upstream, fallback to origin)
    let upstream_res = (do { git remote get-url upstream } | complete)
    let url = if $upstream_res.exit_code == 0 {
        $upstream_res.stdout | str trim
    } else {
        let origin_res = (do { git remote get-url origin } | complete)
        if $origin_res.exit_code != 0 {
            print $"(ansi red_bold)❌ Error:(ansi reset) Neither 'upstream' nor 'origin' remote found."
            return
        }
        $origin_res.stdout | str trim
    }

    print $"(ansi bold)🌿 Branch:(ansi reset)   (ansi green)($branch)(ansi reset)"
    print $"(ansi bold)📦 Git URL:(ansi reset)  (ansi blue_underline)($url)(ansi reset)"

    # 3. Construct HTTPS GitLab MR URL
    let https_url = (git_ssh_to_https_url $url)
    let encoded_branch = ($branch | url encode)
    let final_url = $"($https_url)/-/merge_requests/new?merge_request%5Bsource_branch%5D=($encoded_branch)"

    print $"(ansi cyan)🌐 Opening MR:(ansi reset) (ansi yellow_underline)($final_url)(ansi reset)"

    # 4. Open in browser (supports NixOS default path with fallbacks)
    if ("/run/current-system/sw/bin/xdg-open" | path exists) {
        ^/run/current-system/sw/bin/xdg-open $final_url
    } else if (which xdg-open | is-not-empty) {
        ^xdg-open $final_url
    } else {
        ^open $final_url
    }
}
