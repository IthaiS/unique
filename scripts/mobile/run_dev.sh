#!/usr/bin/env bash
set -euo pipefail
BACKEND_BASE_URL="${BACKEND_BASE_URL:-http://127.0.0.1:8000}"
echo "Running Flutter app (DEV) → $BACKEND_BASE_URL"
flutter run --dart-define=BACKEND_BASE_URL="$BACKEND_BASE_URL"
