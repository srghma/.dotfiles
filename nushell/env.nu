$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""
$env.PROMPT_MULTILINE_INDICATOR = "::: "

$env.NIXPKGS_ALLOW_UNFREE = 1

load-env (open ~/.dotfiles/secrets/aristotle-lean-key.env | from toml)
