module _git_fork {
    use ../lib/log.nu [log-info, log-header, log-err, log-done]

    # Ensure we are inside a git repository
    def _ensure_git_repo [] {
        if ((do { git rev-parse --git-dir } | complete).exit_code != 0) {
            log-err "❌ Not inside a Git repository"
            return false
        }
        true
    }

    # Detect repository name from the 'origin' remote URL, falling back to repo root folder name
    def _detect_current_reponame [] {
        if not (_ensure_git_repo) {
            return null
        }

        let origin_res = (do { git remote get-url origin } | complete)
        if $origin_res.exit_code == 0 {
            let reponame = (
                $origin_res.stdout
                | str trim
                | str trim -r -c '/'
                | path basename
                | str replace -r '\.git$' ''
            )
            if not ($reponame | is-empty) {
                return $reponame
            }
        }

        let root_res = (do { git rev-parse --show-toplevel } | complete)
        if $root_res.exit_code == 0 {
            let reponame = ($root_res.stdout | str trim | path basename)
            if not ($reponame | is-empty) {
                return $reponame
            }
        }

        log-err "❌ Could not determine current repository name from 'origin' remote or directory"
        null
    }

    # Fail-proof remote handling (add if missing, update if pointing elsewhere)
    def _upsert_remote [username: string, remote_url: string] {
        let remotes = (git remote | lines | str trim)
        if ($username in $remotes) {
            let existing_url = (git remote get-url $username | str trim)
            if ($existing_url == $remote_url) {
                log-info $"🔗 Remote '($username)' already exists with URL ($remote_url)"
            } else {
                print $"(ansi yellow_bold)⚠️ Remote '($username)' already exists pointing to ($existing_url), updating to ($remote_url)(ansi reset)"
                try {
                    git remote set-url $username $remote_url
                } catch {
                    log-err $"❌ Failed to update remote '($username)'"
                    return false
                }
            }
        } else {
            log-info $"🔗 git remote add ($username) ($remote_url)"
            try {
                git remote add $username $remote_url
            } catch {
                log-err $"❌ Failed to add remote '($username)'"
                return false
            }
        }
        true
    }

    # Resolve the target branch first so we only fetch what is needed
    def _resolve_target_branch [username: string, branch?: string] {
        if ($branch != null and not ($branch | is-empty)) {
            return $branch
        }
        if ((do { git ls-remote --exit-code --heads $username main } | complete).exit_code == 0) {
            return "main"
        }
        if ((do { git ls-remote --exit-code --heads $username master } | complete).exit_code == 0) {
            return "master"
        }

        log-err $"⚠️ Neither 'main' nor 'master' found on remote '($username)'"
        null
    }

    # Shared core workflow used by all git-add-fork--* commands
    def _git_add_fork_core [username: string, reponame: string, branch?: string] {
        if not (_ensure_git_repo) {
            return
        }

        let remote_url = $"git@github.com:($username)/($reponame).git"
        # url="https://github.com/$username/$reponame/tree/$branch"

        if not (_upsert_remote $username $remote_url) {
            return
        }

        let target_branch = (_resolve_target_branch $username $branch)
        if ($target_branch == null) {
            return
        }

        # Fetch only the needed branch and explicitly map its remote-tracking ref
        log-header $"📥 Fetching '($target_branch)' from '($username)'..."
        try {
            git fetch $username $"+refs/heads/($target_branch):refs/remotes/($username)/($target_branch)"
        } catch {
            log-err $"❌ Failed to fetch ($username)/($target_branch)"
            return
        }

        log-info $"🔀 Merging ($username)/($target_branch)..."
        try {
            git merge $"($username)/($target_branch)"
        } catch {
            log-err $"❌ Merge failed for ($username)/($target_branch)"
            return
        }

        log-done "✨ Done!"
    }

    # example
    # git-add-fork--url "https://github.com/evertonstz/youtube-upload" master
    # git-add-fork--url "https://github.com/jvanbruegge/nixpkgs/tree/isabelle-2026"
    export def git-add-fork--url [url: string, branch?: string] {
        let match = ($url | parse -r 'github\.com[/:](?<username>[^/]+)/(?<reponame>[^/\s]+)(?:/tree/(?<url_branch>[^\s#?]+))?')
        if ($match | is-empty) {
            log-err $"❌ Could not parse GitHub username and repository from URL: ($url)"
            return
        }

        let username = $match.0.username
        let reponame = ($match.0.reponame | str replace -r '\.git$' '')
        let target_branch = if ($branch != null and not ($branch | is-empty)) {
            $branch
        } else {
            $match.0.url_branch
        }

        _git_add_fork_core $username $reponame $target_branch
    }

    # reponame="youtube-upload"
    # prid="youtube-upload:master"
    # username=$(echo $prid | cut -d ':' -f 1) # srghma
    # branch=$(echo $prid | cut -d ':' -f 2)   # master

    # --- Standalone disabled version (kept commented out so env has only 1 func) ---
    # git-add-fork--full "srghma" "youtube-upload" "master"
    export def git-add-fork--full [reponame: string, username: string, branch?: string] {
        _git_add_fork_core $username $reponame $branch
    }

    # example (when inside a cloned repo like nixpkgs):
    # git-add-fork--short "jvanbruegge:isabelle-2026"
    export def git-add-fork--short [prid: string, branch?: string] {
        let parts = ($prid | split row ":")
        let username = ($parts.0 | str trim)
        if ($username | is-empty) {
            log-err $"❌ Could not parse username from: ($prid)"
            return
        }

        let pr_branch = if (($parts | length) > 1) {
            ($parts | skip 1 | str join ":" | str trim)
        } else {
            null
        }

        let reponame = (_detect_current_reponame)
        if ($reponame == null) {
            return
        }

        let target_branch = if ($branch != null and not ($branch | is-empty)) {
            $branch
        } else {
            $pr_branch
        }

        _git_add_fork_core $username $reponame $target_branch
    }
}

use _git_fork [git-add-fork--url, git-add-fork--full, git-add-fork--short]
