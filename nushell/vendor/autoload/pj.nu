# Project directories
# $env.PROJECT_PATHS = ["~/projects", "~/work"]

# Completion
def "nu-complete pj" [token: record, place: record] {
    let projects = (
        $env.PROJECT_PATHS?
        | default [($env.HOME | path join "projects")]
        | each {|p| $p | path expand}
    )

    let prefix = $token.text
    let args = $place.command | skip 1
    let open_mode = ($place.index > 0) and (($args | first | default "") == "open")

    # Find directories matching the current relative path
    let dirs = (
        $projects
        | each {|project|
            let parts = ($prefix | split row "/")
            let has_slash = ($prefix | str contains "/")

            let parent = if $has_slash {
                $parts | drop | str join "/"
            } else {
                ""
            }

            let name = if $has_slash {
                $parts | last
            } else {
                $prefix
            }

            let search = if ($parent | is-empty) {
                $project
            } else {
                $project | path join $parent
            }

            glob ($search | path join $"($name)*")
            | where {|path| ($path | path type) == "dir"}
            | where {|path| not (($path | path basename) | str starts-with ".")}
            | each {|path| $path | path relative-to $project}
        }
        | flatten
        | uniq
        | where {|dir| $dir | str starts-with $prefix}
    )

    if $open_mode {
        $dirs
    } else {
        let action = if ($prefix != "open") and ("open" | str starts-with $prefix) {
            [{
                value: "open"
                style: {fg: yellow attr: b}
            }]
        } else {
            []
        }

        $action | append $dirs
    }
}

# Main command
@complete "nu-complete pj"
def --env pj [...args: string] {
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

    if ($target | is-empty) {
        if $open_mode {
            print -e "Usage: pj [open] <project-or-subfolder>"
            return
        }

        cd ($projects | first)
        return
    }

    let matches = (
        $projects
        | each {|project| $project | path join $target}
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
