# Configure your project directories
# Example:
# $env.PROJECT_PATHS = ["~/projects", "~/work"]

def --env pj [
    ...args: string@"nu-complete pj"
] {
    let open_mode = ($args | first | default "") == "open"

    let target = if $open_mode {
        $args | skip 1 | str join " "
    } else {
        $args | str join " "
    }

    let projects = (
        $env.PROJECT_PATHS?
        | default [($env.HOME | path join "projects")]
        | each {|p| $p | path expand}
    )

    # No arguments: cd to first project directory
    if ($target | is-empty) {
        if $open_mode {
            print -e "Usage: pj [open] <project-or-subfolder>"
            return
        }

        cd ($projects | first)
        return
    }

    # Find matching project or subdirectory
    let matches = (
        $projects
        | each {|project|
            $project | path join $target
        }
        | where {|path|
            ($path | path exists) and (($path | path type) == "dir")
        }
    )

    if ($matches | is-empty) {
        print -e $"No such project or directory: ($target)"
        return
    }

    let path = ($matches | first)

    if $open_mode {
        let editor = ($env.EDITOR? | default "vi")
        let editor_parts = ($editor | split row " ")

        ^($editor_parts | first) ...($editor_parts | skip 1) $path
    } else {
        cd $path
    }
}

# Tab completion
def "nu-complete pj" [] {
    let projects = (
        $env.PROJECT_PATHS?
        | default [($env.HOME | path join "projects")]
        | each {|p| $p | path expand}
    )

    let dirs = (
        $projects
        | each {|project|
            glob ($project | path join "**" | path join "*")
            | each {|path|
                $path
                | path relative-to $project
            }
        }
        | flatten
        | uniq
    )

    ["open"] | append $dirs
}
