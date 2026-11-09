# example
# git-add-fork--url "https://github.com/evertonstz/youtube-upload" master

def git-add-fork--url [url: string, branch?: string] {
    let match = ($url | parse -r 'github\.com[/:](?<username>[^/]+)/(?<reponame>[^/\s]+)')
    if ($match | is-empty) {
        print $"(ansi red_bold)❌ Could not parse GitHub username and repository from URL: ($url)(ansi reset)"
        return
    }

    let username = $match.0.username
    let reponame = ($match.0.reponame | str replace -r '\.git$' '')
    let remote_url = $"git@github.com:($username)/($reponame).git"
    # url="https://github.com/$username/$reponame/tree/$branch"

    # Check if the remote already exists
    let remotes = (git remote | lines | str trim)
    let operation = if ($username in $remotes) { "set-url" } else { "add" }

    print $"(ansi cyan_bold)🔗 git remote ($operation) ($username) ($remote_url)(ansi reset)"
    git remote $operation $username $remote_url

    print $"(ansi yellow_bold)📥 Fetching remote '($username)'...(ansi reset)"
    git fetch $username

    if ($branch == null or ($branch | is-empty)) {
        if ((do { git ls-remote --exit-code $username main } | complete).exit_code == 0) {
            print $"(ansi green_bold)🔀 Merging ($username)/main...(ansi reset)"
            git merge $"($username)/main"
        } else if ((do { git ls-remote --exit-code $username master } | complete).exit_code == 0) {
            print $"(ansi green_bold)🔀 Merging ($username)/master...(ansi reset)"
            git merge $"($username)/master"
        } else {
            print $"(ansi red_bold)⚠️ Neither 'main' nor 'master' found on remote '($username)'(ansi reset)"
        }
    } else {
        print $"(ansi green_bold)🔀 Merging ($username)/($branch)...(ansi reset)"
        git merge $"($username)/($branch)"
    }

    print $"(ansi green_bold)✨ Done!(ansi reset)"
}

# reponame="youtube-upload"
# prid="youtube-upload:master"
# username=$(echo $prid | cut -d ':' -f 1) # srghma
# branch=$(echo $prid | cut -d ':' -f 2)   # master

# --- Standalone disabled version (kept commented out so env has only 1 func) ---
# git-add-fork--full "srghma" "youtube-upload" "master"
def git-add-fork--full [reponame: string, username: string, branch?: string] {
    let url = $"git@github.com:($username)/($reponame).git"
    # url="https://github.com/$username/$reponame/tree/$branch"
    let remotes = (git remote | lines | str trim)
    let operation = if ($username in $remotes) { "set-url" } else { "add" }
    print $"(ansi cyan_bold)🔗 git remote ($operation) ($username) ($url)(ansi reset)"
    git remote $operation $username $url
    git fetch $username
    if ($branch == null or ($branch | is-empty)) {
        if ((do { git ls-remote --exit-code $username main } | complete).exit_code == 0) {
            git merge $"($username)/main"
        } else if ((do { git ls-remote --exit-code $username master } | complete).exit_code == 0) {
            git merge $"($username)/master"
        }
    } else {
        git merge $"($username)/($branch)"
    }
}
