#!/usr/bin/env bash
# Verify SHA256 checksums for the super release contents.
set -euo pipefail
ROOT="${1:-.}"
FILE="CHECKSUMS.txt"
cd "$ROOT"
if ! command -v shasum >/dev/null 2>&1; then
  echo "shasum not found. On Linux, install coreutils and use 'sha256sum -c' instead." >&2
  exit 1
fi
# macOS uses 'shasum -a 256', Linux often uses 'sha256sum'
if grep -q '  ' "$FILE"; then
  # macOS format produced by this pack: "<SHA256>  <path>"
  shasum -a 256 -c "$FILE"
else
  sha256sum -c "$FILE"
fi
echo "✅ All files match CHECKSUMS.txt"
