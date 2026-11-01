import os
import sys

USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"
    RED = "\033[31m"
    DIM = "\033[2m"


def colorize(text: str, color_code: str) -> str:
    return f"{color_code}{text}{Colors.RESET}" if USE_COLOR else text
