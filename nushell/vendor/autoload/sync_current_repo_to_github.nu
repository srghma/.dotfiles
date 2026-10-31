const GITHUB_USER = "sergeynordicresults"

# Syncs the current git repository to GitHub under the configured user
export def sync-current-repo-to-github [] {
    # Disable direnv temporarily within this function's scope
    $env.DIRENV_DISABLE = "true"

    let in_git = (do { git rev-parse --is-inside-work-tree } | complete)
    if $in_git.exit_code != 0 {
        print $"(ansi red_bold)❌ Error:(ansi reset) Not inside a git repository."
        return
    }

    let repo_path = ($env.PWD | path expand)
    let repo_name = ($repo_path | path basename)

    print $"(ansi bold)(ansi blue)=== Processing (ansi cyan)($repo_path)(ansi reset)(ansi bold)(ansi blue) ===(ansi reset)"

    # 1. Handle fork vs new repo
    let upstream_res = (do { git remote get-url upstream } | complete)
    if $upstream_res.exit_code == 0 {
        print $"(ansi cyan)🔁 Detected forked repo (has upstream). Forking on GitHub...(ansi reset)"

        let upstream_url = ($upstream_res.stdout | str trim)
        let repo_fullname = ($upstream_url
            | str replace -r '.*github\.com[:/]' ''
            | str replace -r '\.git$' '')

        let fork_res = (do { gh repo fork $repo_fullname --clone=false --remote=false } | complete)
        if $fork_res.exit_code != 0 {
            print $"(ansi yellow)⚠️  Already forked or error during fork check.(ansi reset)"
        }
    } else {
        print $"(ansi cyan)🧪 Not a fork. Checking if repo exists under (ansi bold)($GITHUB_USER)(ansi reset)..."

        let repo_view = (do { gh repo view $"($GITHUB_USER)/($repo_name)" } | complete)
        if $repo_view.exit_code != 0 {
            print $"(ansi green)🆕 Creating new repo ($GITHUB_USER)/($repo_name)...(ansi reset)"
            do { git remote remove origin } | complete
            gh repo create $"($GITHUB_USER)/($repo_name)" --public --source=. --remote=origin --push
        } else {
            print $"(ansi green)✅ Repo already exists at ($GITHUB_USER)/($repo_name)(ansi reset)"
        }
    }

    # 2. Ensure origin remote points to HTTPS URL
    print $"(ansi cyan)🔗 Setting origin to HTTPS...(ansi reset)"
    let target_origin = $"https://github.com/($GITHUB_USER)/($repo_name).git"
    let origin_check = (do { git remote get-url origin } | complete)

    if $origin_check.exit_code == 0 {
        git remote set-url origin $target_origin
    } else {
        git remote add origin $target_origin
    }

    # 3. Rename branch to main if necessary
    let branch_res = (do { git symbolic-ref --short HEAD } | complete)
    let current_branch = ($branch_res.stdout | str trim)
    if ($current_branch | is-not-empty) and ($current_branch != "main") {
        print $"(ansi cyan)🌿 Renaming branch (ansi bold)($current_branch)(ansi reset) to (ansi bold)main(ansi reset)..."
        git branch -M main
    }

    # 4. Push to origin main
    print $"(ansi cyan)🚀 Pushing to origin main...(ansi reset)"
    do { git push -u origin main }
    if $env.LAST_EXIT_CODE != 0 {
        print $"(ansi yellow)⚠️  Push failed (maybe already up to date or requires merge)(ansi reset)"
    }

    print $"(ansi bold)(ansi green)✅ Done: ($repo_name)(ansi reset)"
}
