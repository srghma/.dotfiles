export def log-step [msg: string] {
    print $"(ansi cyan)($msg)(ansi reset)"
}

export def log-info [msg: string] {
    print $"(ansi blue)($msg)(ansi reset)"
}

export def log-ok [msg: string] {
    print $"(ansi green)($msg)(ansi reset)"
}

export def log-warn [msg: string] {
    print $"(ansi yellow)($msg)(ansi reset)"
}

export def log-err [msg: string] {
    print $"(ansi red_bold)($msg)(ansi reset)"
}

export def log-header [msg: string] {
    print $"(ansi blue_bold)($msg)(ansi reset)"
}

export def log-done [msg: string] {
    print $"(ansi green_bold)($msg)(ansi reset)"
}
