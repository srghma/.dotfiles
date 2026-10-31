# Adds a git remote or updates its URL if it has changed
export def git-remote-add-or-set-url [remote_name: string, url: string] {
    let existing = (do { git remote get-url $remote_name } | complete)

    if $existing.exit_code == 0 {
        let current_url = ($existing.stdout | str trim)
        if $current_url != $url {
            git remote set-url $remote_name $url
            print $"(ansi green)✔(ansi reset) Set remote (ansi cyan)($remote_name)(ansi reset) to (ansi blue_underline)($url)(ansi reset)"
        }
    } else {
        git remote add $remote_name $url
        print $"(ansi green)✔(ansi reset) Added remote (ansi cyan)($remote_name)(ansi reset) (ansi blue_underline)($url)(ansi reset)"
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
        print $"(ansi yellow)💡 Usage:(ansi reset) gh-repo-create-and-push <repo_name> [public|private]"
        return
    }

    if $visibility not-in ["public", "private"] {
        print $"(ansi red_bold)❌ Error:(ansi reset) Visibility must be '(ansi cyan)public(ansi reset)' or '(ansi cyan)private(ansi reset)'"
        return
    }

    let in_git = (do { git rev-parse --is-inside-work-tree } | complete)
    if $in_git.exit_code != 0 {
        print $"(ansi red_bold)❌ Error:(ansi reset) Not inside a git repository."
        return
    }

    # Ensure gh works and is authenticated
    let user_res = (do { gh api user -q .login } | complete)
    let my_gh_user = ($user_res.stdout | str trim)

    if $user_res.exit_code != 0 or ($my_gh_user | is-empty) or ($my_gh_user | str starts-with "{") {
        print $"(ansi red_bold)❌ Error:(ansi reset) Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
        return
    }

    print $"(ansi bold)👤 GitHub user:(ansi reset) (ansi cyan)($my_gh_user)(ansi reset)"
    print $"(ansi bold)📦 Repo name:(ansi reset)   (ansi green)($repo_name)(ansi reset)"
    print $"(ansi bold)🔒 Visibility:(ansi reset)  (ansi yellow)($visibility)(ansi reset)"

    # Delete upstream & origin remotes if they exist (can be wrong)
    do { git remote remove upstream } | complete
    do { git remote remove origin } | complete

    # Create repo on GitHub and set origin
    print $"(ansi cyan)🚀 Creating GitHub repo...(ansi reset)"
    if $visibility == "public" {
        gh repo create $repo_name --source=. --remote=origin --public
    } else {
        gh repo create $repo_name --source=. --remote=origin --private
    }

    # Ensure main branch
    do { git branch -M main } | complete

    # Push to origin main
    print $"(ansi cyan)📤 Pushing to main...(ansi reset)"
    git push -u origin main

    print $"(ansi green_bold)🎉 Done!(ansi reset)"
    git remote -v
}

# Automatically sets up origin (your fork) and upstream (parent repository)
export def git-remote-setup-fork [] {
    # 1. Get current authentic GitHub username
    let user_res = (do { gh api user -q .login } | complete)
    let my_gh_user = ($user_res.stdout | str trim)

    if $user_res.exit_code != 0 or ($my_gh_user | is-empty) or ($my_gh_user | str starts-with "{") {
        print $"(ansi red_bold)❌ Error:(ansi reset) Could not retrieve GitHub username. Is 'gh' installed and authenticated?"
        return
    }

    # 2. Get repository name from current origin
    let origin_res = (do { git remote get-url origin } | complete)
    if $origin_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Error:(ansi reset) No 'origin' remote found. Cannot determine repository."
        return
    }
    let current_origin_url = ($origin_res.stdout | str trim)
    let repo_name = ($current_origin_url | split row '/' | last | split row ':' | last | str replace -r '\.git$' '')

    print $"(ansi bold)👤 Detected User:(ansi reset) (ansi cyan)($my_gh_user)(ansi reset)"
    print $"(ansi bold)📦 Detected Repo:(ansi reset) (ansi green)($repo_name)(ansi reset)"

    # 3. Ensure the fork exists on GitHub
    print $"(ansi cyan)🍴 Ensuring fork exists on GitHub...(ansi reset)"
    let fork_res = (do { gh repo fork --clone=false --remote=true } | complete)
    if $fork_res.exit_code != 0 {
        print $"(ansi yellow)ℹ️  Fork already exists or check skipped.(ansi reset)"
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
        print $"(ansi red_bold)❌ Error:(ansi reset) Current origin belongs to you, but GitHub says it has no parent."
        print $"(ansi red_bold)❌ Error:(ansi reset) Cannot determine upstream. Exiting."
        return
    }

    # 5. Security/Logic Check: Ensure Upstream is NOT me
    if ($upstream_url | str contains $my_gh_user) {
        print $"(ansi red_bold)🚫 Aborting:(ansi reset) The determined upstream URL '($upstream_url)' belongs to you."
        print $"(ansi yellow)⚠️  This usually happens if you cloned your own fork initially and it has no parent.(ansi reset)"
        return
    }

    # 6. Apply Remotes
    let my_fork_url = $"ssh://git@github.com/($my_gh_user)/($repo_name).git"

    print $"(ansi cyan)⚙️  Configuring remotes...(ansi reset)"
    git-remote-add-or-set-url upstream $upstream_url
    git-remote-add-or-set-url origin $my_fork_url

    print $"(ansi cyan)📥 Fetching all remotes...(ansi reset)"
    git fetch --all
    git remote -v
}

# Adds a remote for a PR contributor and merges their branch
# Usage:
#   git-remote-add-pr <username:branch>
#   git-remote-add-pr <github-pr-url>
export def git-remote-add-pr [input?: string] {
    if ($input | is-empty) {
        print $"(ansi yellow)💡 Usage:(ansi reset) git-remote-add-pr <username:branch> OR <github-pr-url>"
        return
    }

    # 1. Handle GitHub PR URL input
    let prid = if ($input | str contains "github.com/") and ($input | str contains "/pull/") {
        print $"(ansi cyan)🔗 Detected GitHub PR URL. Fetching details via gh...(ansi reset)"
        let pr_res = (do {
            gh pr view $input --json headRepositoryOwner,headRefName --template '{{.headRepositoryOwner.login}}:{{.headRefName}}'
        } | complete)
        let res_str = ($pr_res.stdout | str trim)

        if $pr_res.exit_code != 0 or ($res_str | is-empty) {
            print $"(ansi red_bold)❌ Error:(ansi reset) Could not fetch PR details. Ensure 'gh' is authenticated and the URL is valid."
            return
        }
        $res_str
    } else {
        $input
    }

    # 2. Extract username and branch from "user:branch"
    if not ($prid | str contains ":") {
        print $"(ansi red_bold)❌ Error:(ansi reset) Input must be in format 'username:branch' or a GitHub PR URL."
        return
    }

    let parts = ($prid | split row ':')
    let username = ($parts | get 0 | str trim)
    let branch = ($parts | get 1 | str trim)

    # 3. Get repository name from origin
    let origin_res = (do { git remote get-url origin } | complete)
    if $origin_res.exit_code != 0 {
        print $"(ansi red_bold)❌ Error:(ansi reset) No 'origin' remote found. Cannot determine repository name."
        return
    }

    let origin = ($origin_res.stdout | str trim)
    let reponame = ($origin | split row '/' | last | split row ':' | last | str replace -r '\.git$' '')
    let url = $"git@github.com:($username)/($reponame).git"

    # 4. Construct URL and apply
    print $"(ansi cyan)🔗 Setting up remote for (ansi bold)($username)(ansi reset)..."
    git-remote-add-or-set-url $username $url

    print $"(ansi cyan)📥 Fetching (ansi bold)($username)(ansi reset)..."
    git fetch $username

    print $"(ansi cyan)🔀 Merging (ansi bold)($username)/($branch)(ansi reset)..."
    git merge $"($username)/($branch)"

    print $"(ansi green_bold)✅ Successfully merged ($username):($branch)(ansi reset)"
}
