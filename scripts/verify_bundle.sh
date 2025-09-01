#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
FILE="CHECKSUMS.txt"
cd "$ROOT"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 -c "$FILE"
else
  sha256sum -c "$FILE"
fi
echo "✅ All files match CHECKSUMS.txt"
