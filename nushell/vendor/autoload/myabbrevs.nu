const my_abbreviations = {
    # Custom Git
    gs: "git status"

    # From zshrc
    l: "eza --long --all"
    lt: "eza --tree --total-size --git-ignore --all"
    ltall: "eza --tree --total-size --all"
    nii: "nix profile add"
    node: "bun"
    antigravity: "antigravity-ide"

    # From zsh/system.sh
    n: "nvim"
    vim: "nvim"
    vimdiff: "nvim -d"
    # r: "ranger"
    r: "yazi"
    # z: "zsh"
    top: "htop"
    wifi: "nmtui"
    sctl: "systemctl"
    "share-wifi": "sudo create_ap wlp3s0 enp2s0 SrghmaWifi suckmydick666"
    pjdot: "cd ~/.dotfiles"
    pjodot: "cd ~/.dotfiles; nvim"
    # nh: "n-history"
    rmf: "rm -rfd"
}

export-env {
    # Safely get current abbreviations if already defined, or fallback to an empty record
    let current = ($env.config? | get -o abbreviations | default {})
    $env.config.abbreviations = ($current | merge $my_abbreviations)
}
