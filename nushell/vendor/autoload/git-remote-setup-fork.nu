module _git_remote_setup_fork {
    use ../lib/log.nu [log-step, log-info, log-ok, log-warn, log-err, log-header, log-done]

    # Adds a git remote or updates its URL if it has changed
    export def git-remote-add-or-set-url [remote_name: string, url: string] {
        let existing = (do { git remote get-url $remote_name } | complete)

        if $existing.exit_code == 0 {
            let current_url = ($existing.stdout | str trim)
            if $current_url != $url {
                git remote set-url $remote_name $url
                log-ok $"✔ Set remote (ansi cyan)($remote_name)(ansi reset) to (ansi blue_underline)($url)(ansi reset)"
            }
        } else {
            git remote add $remote_name $url
            log-ok $"✔ Added remote (ansi cyan)($remote_name)(ansi reset) (ansi blue_underline)($url)(ansi reset)"
        }
    }

    # Creates a GitHub repo from current directory, sets origin, and pushes main
    # Usage:
    #   gh-repo-create-and-push myrepo
    #   gh-repo-create-and-push myrepo public
    #   gh-repo-create-and-push myrepo private
    export def gh-repo-create-and-push [
        repo_name?: string,
        visibility: string = "public"
    ] {
        if ($repo_name | is-empty) {
            log-warn "💡 Usage: gh-repo-create-and-push <repo_name> [public|private]"
            return
        }

        if $visibility not-in ["public", "private"] {
            log-err "❌ Error: Visibility must be '(ansi cyan)public(ansi reset)' or '(ansi cyan)private(ansi reset)'"
            return
        }

        let in_git = (do { git rev-parse --is-inside-work-tree } | complete)
        if $in_git.exit_code != 0 {
            log-err "❌ Error: Not inside a git repository."
            return
        }

        # Ensure gh works and is authenticated
        let user_res = (do { gh api user -q .login } | complete)
        let my_gh_user = ($user_res.stdout | str trim)

        if $user_res.exit_code != 0 or ($my_gh_user | is-empty) or ($my_gh_user | str starts-with "{") {
            log-err "❌ Error: Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
            return
        }

        print $"(ansi default_bold)👤 GitHub user:(ansi reset) (ansi cyan)($my_gh_user)(ansi reset)"
        print $"(ansi default_bold)📦 Repo name:(ansi reset)   (ansi green)($repo_name)(ansi reset)"
        print $"(ansi default_bold)🔒 Visibility:(ansi reset)  (ansi yellow)($visibility)(ansi reset)"

        # Delete upstream & origin remotes if they exist (can be wrong)
        do { git remote remove upstream } | complete
        do { git remote remove origin } | complete

        # Create repo on GitHub and set origin
        log-step "🚀 Creating GitHub repo..."
        if $visibility == "public" {
            gh repo create $repo_name --source=. --remote=origin --public
        } else {
            gh repo create $repo_name --source=. --remote=origin --private
        }

        # Ensure main branch
        do { git branch -M main } | complete

        # Push to origin main
        log-step "📤 Pushing to main..."
        git push -u origin main

        log-done "🎉 Done!"
        git remote -v
    }

    # Automatically sets up origin (your fork) and upstream (parent repository)
    export def git-remote-setup-fork [] {
        # 1. Get current authentic GitHub username
        let user_res = (do { gh api user -q .login } | complete)
        let my_gh_user = ($user_res.stdout | str trim)

        if $user_res.exit_code != 0 or ($my_gh_user | is-empty) or ($my_gh_user | str starts-with "{") {
            log-err "❌ Error: Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
            return
        }

        # 2. Get repository name from current origin
        let origin_res = (do { git remote get-url origin } | complete)
        if $origin_res.exit_code != 0 {
            log-err "❌ Error: No 'origin' remote found. Cannot determine repository."
            return
        }
        let current_origin_url = ($origin_res.stdout | str trim)
        let repo_name = ($current_origin_url | split row '/' | last | split row ':' | last | str replace -r '\.git$' '')

        print $"(ansi default_bold)👤 Detected User:(ansi reset) (ansi cyan)($my_gh_user)(ansi reset)"
        print $"(ansi default_bold)📦 Detected Repo:(ansi reset) (ansi green)($repo_name)(ansi reset)"

        # 3. Ensure the fork exists on GitHub
        log-step "🍴 Ensuring fork exists on GitHub..."
        let fork_res = (do { gh repo fork --clone=false --remote=true } | complete)
        if $fork_res.exit_code != 0 {
            log-warn "ℹ️  Fork already exists or check skipped."
        }

        # 4. Determine the correct Upstream URL
        let parent_res = (do { gh repo view --json parent -q .parent.sshUrl } | complete)
        let parent_ssh_url = ($parent_res.stdout | str trim)

        let upstream_url = if ($parent_res.exit_code == 0) and ($parent_ssh_url | is-not-empty) and ($parent_ssh_url != "null") and not ($parent_ssh_url | str starts-with "{") {
            # Case A: The repo is a fork, use the real parent
            $parent_ssh_url
        } else if not ($current_origin_url | str contains $my_gh_user) {
            # Case B: Current origin does not belong to me, assume it is upstream
            $current_origin_url
        } else {
            log-err "❌ Error: Current origin belongs to you, but GitHub says it has no parent."
            log-err "❌ Error: Cannot determine upstream. Exiting."
            return
        }

        # 5. Security/Logic Check: Ensure Upstream is NOT me
        if ($upstream_url | str contains $my_gh_user) {
            log-err $"🚫 Aborting: The determined upstream URL '($upstream_url)' belongs to you."
            log-warn "⚠️  This usually happens if you cloned your own fork initially and it has no parent."
            return
        }

        # 6. Apply Remotes
        let my_fork_url = $"ssh://git@github.com/($my_gh_user)/($repo_name).git"

        log-step "⚙️  Configuring remotes..."
        git-remote-add-or-set-url upstream $upstream_url
        git-remote-add-or-set-url origin $my_fork_url

        log-step "📥 Fetching all remotes..."
        git fetch --all
        git remote -v
    }

    # Adds a remote for a PR contributor and merges their branch
    # Usage:
    #   git-remote-add-pr <username:branch>
    #   git-remote-add-pr <github-pr-url>
    export def git-remote-add-pr [input?: string] {
        if ($input | is-empty) {
            log-warn "💡 Usage: git-remote-add-pr <username:branch> OR <github-pr-url>"
            return
        }

        # 1. Handle GitHub PR URL input
        let prid = if ($input | str contains "github.com/") and ($input | str contains "/pull/") {
            log-step "🔗 Detected GitHub PR URL. Fetching details via gh..."
            let pr_res = (do {
                gh pr view $input --json headRepositoryOwner,headRefName --template '{{.headRepositoryOwner.login}}:{{.headRefName}}'
            } | complete)
            let res_str = ($pr_res.stdout | str trim)

            if $pr_res.exit_code != 0 or ($res_str | is-empty) {
                log-err "❌ Error: Could not fetch PR details. Ensure 'gh' is authenticated and the URL is valid."
                return
            }
            $res_str
        } else {
            $input
        }

        # 2. Extract username and branch from "user:branch"
        if not ($prid | str contains ":") {
            log-err "❌ Error: Input must be in format 'username:branch' or a GitHub PR URL."
            return
        }

        let parts = ($prid | split row ':')
        let username = ($parts | get 0 | str trim)
        let branch = ($parts | get 1 | str trim)

        # 3. Get repository name from origin
        let origin_res = (do { git remote get-url origin } | complete)
        if $origin_res.exit_code != 0 {
            log-err "❌ Error: No 'origin' remote found. Cannot determine repository name."
            return
        }

        let origin = ($origin_res.stdout | str trim)
        let reponame = ($origin | split row '/' | last | split row ':' | last | str replace -r '\.git$' '')
        let url = $"git@github.com:($username)/($reponame).git"

        # 4. Construct URL and apply
        log-step $"🔗 Setting up remote for (ansi default_bold)($username)(ansi reset)..."
        git-remote-add-or-set-url $username $url

        log-step $"📥 Fetching (ansi default_bold)($username)(ansi reset)..."
        git fetch $username

        log-step $"🔀 Merging (ansi default_bold)($username)/($branch)(ansi reset)..."
        git merge $"($username)/($branch)"

        log-done $"✅ Successfully merged ($username):($branch)"
    }
}

use _git_remote_setup_fork [
    git-remote-add-or-set-url,
    gh-repo-create-and-push,
    git-remote-setup-fork,
    git-remote-add-pr,
]
