import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor

def get_non_gitignored_files():
    cmd = ["git", "ls-files", "-co", "--exclude-standard"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return [f for f in result.stdout.strip().split("\n") if f]

patterns = [
    (re.compile(r'\bif_true\b'), 'ite_true'),
    (re.compile(r'\bif_false\b'), 'ite_false'),
    (re.compile(r'\bif_pos\b'), 'ite_eq_left'),
    (re.compile(r'\bif_neg\b'), 'ite_eq_right'),
]

skip_extensions = {".png", ".jpg", ".jpeg", ".pdf", ".ico", ".tar", ".gz", ".zip", ".woff", ".woff2", ".ttf"}

def process_file(file_path):
    ext = os.path.splitext(file_path)[1].lower()
    if ext in skip_extensions:
        return None

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except (UnicodeDecodeError, OSError):
        return None

    new_content = content
    counts = {}
    for pattern, replacement in patterns:
        new_content, n = pattern.subn(replacement, new_content)
        if n > 0:
            counts[pattern.pattern] = n

    if new_content != content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        return (file_path, counts)

    return None

def main():
    files = get_non_gitignored_files()
    modified_files = []
    total_counts = {"if_true": 0, "if_false": 0, "if_pos": 0, "if_neg": 0}

    with ThreadPoolExecutor() as executor:
        for res in executor.map(process_file, files):
            if res:
                file_path, counts = res
                modified_files.append(file_path)
                for pat, n in counts.items():
                    key = pat.replace(r'\b', '')
                    total_counts[key] += n

    import json
    print(json.dumps({
        "modifiedFilesCount": len(modified_files),
        "totalReplacements": total_counts,
        "sampleModified": modified_files[:10]
    }, indent=2))

if __name__ == "__main__":
    main()
