# Parses a Git URL (HTTPS, SSH, or GitHub file/blob/tree URL)
# Returns a structured record: { owner, repo, host, clone_url }
#
# Examples:
#   git-parse-url "https://github.com/srghma/repo/blob/main/LambdaP.lean"
#   "git@github.com:srghma/repo.git" | git-parse-url
export def git-parse-url [
    url?: string
]: [string -> record, nothing -> record] {
    let raw = ($in | default $url)
    if ($raw | is-empty) {
        error make { msg: "Missing URL argument or pipeline input" }
    }

    let is_ssh = ($raw | str starts-with "git@")
    let parsed_info = if $is_ssh {
        let clean = ($raw | str replace -r '^git@' '' | split row ":" | where ($it != ""))
        let host = ($clean | get 0?)
        let path_segments = ($clean | get 1? | default "" | split row "/" | where ($it != ""))
        let owner = ($path_segments | get 0?)
        let repo = ($path_segments | get 1? | default "" | str replace -r '\.git$' '')

        {
            owner: $owner,
            repo: $repo,
            host: $host,
            clone_url: $raw,
        }
    } else {
        let parsed = ($raw | url parse)
        let segments = ($parsed.path | split row "/" | where ($it != ""))
        let owner = ($segments | get 0?)
        let repo = ($segments | get 1? | default "" | str replace -r '\.git$' '')
        let clone_url = $"($parsed.scheme)://($parsed.host)/($owner)/($repo).git"

        {
            owner: $owner,
            repo: $repo,
            host: $parsed.host,
            clone_url: $clone_url,
        }
    }

    if ($parsed_info.repo | is-empty) {
        error make { msg: $"Could not parse a repository name from: '($raw)'" }
    }

    $parsed_info
}

# Clones a repository into a target directory only if it doesn't already exist.
# Accepts a repo record from `git-parse-url` or a raw URL string.
export def git-clone-if-missing [
    repo_or_url: any,
    target_dir: path
] {
    let repo_info = if ($repo_or_url | describe | str starts-with "record") {
        $repo_or_url
    } else {
        git-parse-url $repo_or_url
    }

    if not ($target_dir | path exists) {
        print $"(ansi cyan)🚀 Cloning (ansi cyan_bold)($repo_info.repo)(ansi reset)(ansi cyan) from (ansi cyan_bold)($repo_info.clone_url)(ansi reset)(ansi cyan)...(ansi reset)"

        ^git clone $repo_info.clone_url $target_dir
        if $env.LAST_EXIT_CODE != 0 {
            error make { msg: $"Git clone failed for ($repo_info.clone_url)" }
        }
        print $"(ansi green_bold)✅ Cloned ($repo_info.repo) successfully!(ansi reset)"
    } else {
        print $"(ansi yellow)⚡ Directory (ansi yellow_bold)($repo_info.repo)(ansi reset)(ansi yellow) already exists, skipping clone.(ansi reset)"
    }
}

# Clones a Git repo into ~/projects (or custom dir) and switches into it.
# Supports raw HTTPS/SSH URLs and GitHub blob/tree URLs via parameter or pipeline.
export def --env git-clone-to-pj [
    url?: string,
    dir?: path
] {
    let raw_url = ($in | default $url)
    if ($raw_url | is-empty) {
        error make { msg: "Usage: git-clone-to-pj <url> [dir] OR <url> | git-clone-to-pj" }
    }

    let repo_info = (git-parse-url $raw_url)
    let projects_root = ($dir | default ("~/projects" | path expand))

    if not ($projects_root | path exists) {
        print $"(ansi yellow)📁 Projects directory not found. Creating (ansi yellow_bold)($projects_root)(ansi reset)..."
        mkdir $projects_root
    }

    let target_dir = ($projects_root | path join $repo_info.repo)

    # Clone if not already present
    git-clone-if-missing $repo_info $target_dir

    # Change directory in current shell session
    cd $target_dir
    print $"(ansi green_bold)📂 Now in: (ansi reset)(ansi cyan_bold)($target_dir)(ansi reset)"
}
