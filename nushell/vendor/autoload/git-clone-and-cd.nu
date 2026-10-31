# Clone a repository into ~/projects and cd into it
def --env git-clone-and-cd [url: string] {
    let repo_name = ($url | path basename | str replace -r '\.git$' '')

    print $"(ansi cyan_bold)📁 Navigating to ~/projects...(ansi reset)"
    cd ~/projects

    print $"(ansi yellow_bold)📥 Cloning ($url)...(ansi reset)"
    git clone $url

    print $"(ansi green_bold)📂 Entering ($repo_name)...(ansi reset)"
    cd $"~/projects/($repo_name)"

    print $"(ansi green_bold)✨ Done!(ansi reset)"
}
