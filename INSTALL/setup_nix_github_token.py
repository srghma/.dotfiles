#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

import os
import re
import stat
import sys
import urllib.error
import urllib.request
from pathlib import Path

# Try to use dotfiles lib, fallback cleanly if executed standalone
try:
    from lib.colors import Colors, colorize
except ImportError:
    class Colors:
        BOLD = "\033[1m"
        GREEN = "\033[32m"
        YELLOW = "\033[33m"
        RED = "\033[31m"
        CYAN = "\033[36m"
        DIM = "\033[2m"
        RESET = "\033[0m"

    def colorize(text: str, color: str) -> str:
        return f"{color}{text}{Colors.RESET}"

try:
    from lib.config import HOME
except ImportError:
    HOME = Path.home()

NIX_CONF_DIR = HOME / ".config" / "nix"
NIX_CONF_PATH = NIX_CONF_DIR / "nix.conf"

TOKEN_URL = "https://github.com/settings/tokens/new?description=nix-rate-limit"


def check_existing_token(path: Path) -> None:
    """Error early if a github.com token is already present in nix.conf."""
    if not path.exists():
        return

    content = path.read_text(encoding="utf-8")
    for lineno, line in enumerate(content.splitlines(), start=1):
        stripped = line.strip()
        # Ignore comments
        if stripped.startswith("#"):
            continue

        # Check for access-tokens / extra-access-tokens with github.com
        if re.search(r"\b(?:extra-)?access-tokens\s*=.*\bgithub\.com=", line):
            print(
                colorize("❌ Error: GitHub token already configured!", Colors.RED),
                file=sys.stderr,
            )
            print(
                f"Found at {colorize(str(path), Colors.BOLD)}:{colorize(str(lineno), Colors.YELLOW)}:\n"
                f"  {colorize(line.strip(), Colors.DIM)}",
                file=sys.stderr,
            )
            sys.exit(1)


def verify_github_token(token: str) -> int:
    """Verify token against GitHub API and return rate limit."""
    req = urllib.request.Request(
        "https://api.github.com/rate_limit",
        headers={
            "Authorization": f"Bearer {token}",
            "User-Agent": "nix-config-setup",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            rate_limit = int(resp.headers.get("x-ratelimit-limit", 0))
            return rate_limit
    except urllib.error.HTTPError as err:
        if err.code == 401:
            raise ValueError("GitHub rejected the token (401 Bad credentials).") from err
        raise ValueError(f"GitHub API error: HTTP {err.code} - {err.reason}") from err
    except urllib.error.URLError as err:
        raise ValueError(f"Network error while verifying token: {err.reason}") from err


def main() -> int:
    print(colorize("==> Checking Nix configuration...", Colors.BOLD))

    # 1. Early check before bothering the user
    check_existing_token(NIX_CONF_PATH)

    # 2. Instructions
    print("\n" + colorize("==> GitHub Personal Access Token Required", Colors.BOLD))
    print(
        f"1. Go to: {colorize(TOKEN_URL, Colors.CYAN)}\n"
        f"   (or GitHub Settings → Developer Settings → Personal Access Tokens → Tokens (classic))\n"
        f"2. {colorize('Do NOT select any scopes/permissions.', Colors.YELLOW)}\n"
        f"   A token with {colorize('0 permissions', Colors.BOLD)} still gets the full "
        f"{colorize('5,000 requests/hour', Colors.GREEN)} rate limit for public repos."
    )
    print()

    # 3. Prompt user for token
    try:
        raw_token = input(colorize("Paste your GitHub token: ", Colors.BOLD)).strip()
    except (KeyboardInterrupt, EOFError):
        print("\nAborted.")
        return 1

    if not raw_token:
        print(colorize("❌ Error: Token cannot be empty.", Colors.RED), file=sys.stderr)
        return 1

    # Basic shape validation
    if not (raw_token.startswith("ghp_") or raw_token.startswith("github_pat_")):
        print(
            colorize(
                "⚠️  Warning: Token does not start with expected prefix (ghp_ or github_pat_).",
                Colors.YELLOW,
            )
        )

    # 4. Verify token online
    print("Verifying token with GitHub API...", end=" ", flush=True)
    try:
        limit = verify_github_token(raw_token)
        print(colorize(f"OK! (Rate limit: {limit} requests/hr)", Colors.GREEN))
    except ValueError as e:
        print(colorize(f"FAILED!\n❌ {e}", Colors.RED), file=sys.stderr)
        return 1

    # 5. Write to nix.conf (prepend if not empty)
    NIX_CONF_DIR.mkdir(parents=True, exist_ok=True)

    new_entry = f"access-tokens = github.com={raw_token}\n"
    old_content = NIX_CONF_PATH.read_text(encoding="utf-8") if NIX_CONF_PATH.exists() else ""

    if old_content.strip():
        updated_content = f"{new_entry}\n{old_content.lstrip()}"
    else:
        updated_content = new_entry

    NIX_CONF_PATH.write_text(updated_content, encoding="utf-8")

    # 6. Secure file permissions (rw-------)
    os.chmod(NIX_CONF_PATH, stat.S_IRUSR | stat.S_IWUSR)

    print(
        f"\n{colorize('🔗 [CONFIGURED]', Colors.GREEN)} "
        f"Saved to {colorize(str(NIX_CONF_PATH), Colors.BOLD)} (mode 0600)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
