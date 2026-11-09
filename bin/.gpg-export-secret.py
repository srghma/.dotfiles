#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path

OUTPUT = Path.home() / ".dotfiles/secrets/gpg/secret.gpg"

# Maximum 10 candidates.
CANDIDATES = [
]

def run(*args, input=None):
    return subprocess.run(
        ["gpg", *args],
        input=input,
        capture_output=True,
    )

def get_fingerprints():
    result = run("--with-colons", "--list-secret-keys")

    if result.returncode != 0:
        raise RuntimeError(result.stderr.decode())

    fingerprints = []
    awaiting_fingerprint = False

    for line in result.stdout.decode().splitlines():
        fields = line.split(":")
        if fields[0] == "sec":
            awaiting_fingerprint = True
        elif fields[0] == "fpr" and awaiting_fingerprint:
            fingerprints.append(fields[9])
            awaiting_fingerprint = False

    return fingerprints

def export_key(fingerprint):
    for i, candidate in enumerate(CANDIDATES, 1):
        result = run(
            "--batch",
            "--yes",
            "--pinentry-mode", "loopback",
            "--passphrase-fd", "0",
            "--armor",
            "--export-secret-keys",
            fingerprint,
            input=(candidate + "\n").encode(),
        )

        if (
            result.returncode == 0
            and b"BEGIN PGP PRIVATE KEY BLOCK" in result.stdout
        ):
            print(f"  ✓ Candidate {i} worked")
            return result.stdout

        print(f"  ✗ Candidate {i} failed")

    raise RuntimeError(f"Could not unlock key {fingerprint}")

def main():
    fingerprints = get_fingerprints()

    if not fingerprints:
        raise RuntimeError("No secret keys found")

    print(f"Found {len(fingerprints)} secret keys")

    exported = []

    for fingerprint in fingerprints:
        print(f"\nExporting {fingerprint}...")
        exported.append(export_key(fingerprint))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    # Only overwrite the backup after every key was exported.
    OUTPUT.write_bytes(b"\n".join(exported))
    OUTPUT.chmod(0o600)

    print(f"\n✓ Saved {OUTPUT}")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\nERROR: {e}", file=sys.stderr)
        sys.exit(1)
