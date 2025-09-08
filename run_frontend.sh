#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="${BACKEND_BASE_URL:-http://127.0.0.1:8000}"
# If first arg looks like a URL, use it and shift
if [[ "${1:-}" =~ ^https?:// ]]; then BASE_URL="$1"; shift; fi

echo "› BACKEND_BASE_URL=${BASE_URL}"
cd "${ROOT}/foodlabel-ai/mobile"

if [[ -x scripts/enable_windows.sh ]]; then
  echo "› Running scripts/enable_windows.sh"
  ./scripts/enable_windows.sh || true
fi

command -v flutter >/dev/null 2>&1 || { echo "✖ Flutter not found in PATH"; exit 1; }
exec flutter run -d windows --dart-define="BACKEND_BASE_URL=${BASE_URL}" "$@"
