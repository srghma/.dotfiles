# config.nu
#
# Installed by:
# version = "0.115.1"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings,
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# 1. Disable the startup banner
$env.config.show_banner = false

# 2. Table styling (rounded, basic, compact, light, reinforced)
$env.config.table.mode = "rounded"

# 3. Enable Vi mode (default is "emacs")
$env.config.edit_mode = "vi"

# 4. History settings
$env.config.history = {
    file_format: "plaintext" # or "sqlite" for rich metadata
    max_size: 100_000
    sync_on_enter: true
}

# 5. Shell aliases
alias ll = ls -l
alias la = ls -a
alias g = git
alias nix-switch = sudo nixos-rebuild switch

# 6. Custom helper functions
def mkcd [dir: string] {
    mkdir $dir
    cd $dir
}

# $env.config.extract_prompt_indicator = false
# $env.PROMPT_INDICATOR = ""
# $env.PROMPT_INDICATOR_VI_INSERT = ""
# $env.PROMPT_INDICATOR_VI_NORMAL = ""
# $env.PROMPT_MULTILINE_INDICATOR = "::: "
