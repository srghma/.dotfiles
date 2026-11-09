from enum import Enum, auto
from typing import Tuple, TypeAlias


class Action(Enum):
    UNLINK = auto()
    LINK_SRGHMA = auto()
    LINK_SRGHMA_AND_TESTUSER = auto()


# ---------------------------------------------------------------------------
# VS Code permutations
# ---------------------------------------------------------------------------
VSCODE_USER_DIRS = (
    ".config/Code/User",
    ".config/Code - Insiders/User",
    ".config/Code - OSS/User",
    ".config/VSCodium/User",
    ".config/Cursor/User",
    ".config/Windsurf/User",
    ".antigravity-ide/User",
    ".antigravity/User",
    ".config/Antigravity IDE/User",
)

VSCODE_TARGETS = (
    ("🤝", "settings.json", "Code/settings.json"),
    ("❌", "extensions.json", "Code/extensions.json"),
    ("🤝", "snippets", "Code/snippets"),
)

VSCODE_LINKS = tuple(
    (action, f"{d}/{target}", src)
    for d in VSCODE_USER_DIRS
    for action, target, src in VSCODE_TARGETS
)


# ---------------------------------------------------------------------------
# Raw definitions (3 items with emoji, or 2 items for default)
# ---------------------------------------------------------------------------
RawEntry: TypeAlias = Tuple[str, str] | Tuple[str, str, str]

RAW_CONFIG: Tuple[RawEntry, ...] = (
    ("❌", ".zshrc", "zshrc"),
    ("❌", ".tmux.conf", "tmux.conf"),
    ("🤝", ".i3/config", "i3/config"),
    ("🤝", ".config/i3status-rust/config.toml", "i3status-rust/config.toml"),
    ("❌", ".i3/conky-wrapper", "i3/conky-wrapper"),
    ("❌", ".i3/conkyrc", "i3/conkyrc"),
    ("❌", ".config/joshuto", "joshuto"),
    ("❌", ".config/ranger/commands.py", "ranger/commands.py"),
    ("❌", ".config/ranger/rc.conf", "ranger/rc.conf"),
    ("❌", ".config/ranger/scope.sh", "ranger/scope.sh"),
    ("🤝", ".stack/config.yaml", "stack-global.yaml"),
    ("🤝", ".gitconfig", "gitconfig"),
    ("🤝", ".config/git/ignore", "gitignore_global"),
    ("🤝", ".ctags", "ctags"),
    (".ncmpcpp/bindings", "ncmpcpp_bindings"),  # Default: srghma only
    ("❌", ".config/kitty", "kitty"),
    ("🤝", ".commitlintrc.yml", "commitlintrc.yml"),
    ("🤝", ".local/share/applications/mimeapps.list", "mimeapps.list"),
    ("🤝", ".config/mimeapps.list", "mimeapps.list"),
    ("🤝", ".Xresources", "Xresources"),
    ("🤝", ".Xresources.d", "Xresources.d"),
    ("🤝", ".config/nvim", "nvim"),
    ("🤝", ".cabal/config", "cabal_config"),
    (".gnupg/gpg-agent.conf", "gpg-agent.conf"),  # Default: srghma only (NEVER share)
    ("❌", ".config/kak", "kak"),
    ("❌", ".config/doom", "doom"),
    ("🤝", ".config/rofi", "rofi"),
    ("🤝", ".config/nushell", "nushell"),
    ("🤝", ".local/share/nushell/vendor/autoload", "nushell/vendor/autoload"),
    ("❌", ".config/starship.toml", "starship.toml"),
    ("🤝", ".config/oh-my-posh/config.json", "oh-my-posh/config.json"),
    ("🤝", ".config/yazi", "yazi"),
    ("🤝", ".config/wezterm/wezterm.lua", "wezterm.lua"),
    ("🤝", ".config/flameshot/flameshot.ini", "flameshot.ini"),
    ("❌", ".bunfig.toml", ".bunfig.toml"),
    ("🤝", ".config/carapace/specs", "carapace/specs"),
) + VSCODE_LINKS


# ---------------------------------------------------------------------------
# Normalization into typed Action enum
# ---------------------------------------------------------------------------
def _normalize(entry: RawEntry) -> Tuple[Action, str, str]:
    if len(entry) == 2:
        dst, src = entry
        # Also handles inline prefixes if you ever write ("❌.zshrc", "zshrc")
        if dst.startswith("❌"):
            return (Action.UNLINK, dst.removeprefix("❌"), src)
        if dst.startswith("🤝"):
            return (Action.LINK_SRGHMA_AND_TESTUSER, dst.removeprefix("🤝"), src)
        return (Action.LINK_SRGHMA, dst, src)

    action_str, dst, src = entry
    match action_str:
        case Action() as act:
            return (act, dst, src)
        case "❌":
            return (Action.UNLINK, dst, src)
        case "🤝":
            return (Action.LINK_SRGHMA_AND_TESTUSER, dst, src)
        case "" | "🔗":
            return (Action.LINK_SRGHMA, dst, src)
        case _:
            raise ValueError(f"Unknown action {action_str!r} for {dst} -> {src}")


# Exported typed result:
INHOME_INDOTFILES: Tuple[Tuple[Action, str, str], ...] = tuple(
    _normalize(entry) for entry in RAW_CONFIG
)
