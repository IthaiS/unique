#!/usr/bin/env bash
set -euo pipefail
BACKEND_BASE_URL="${BACKEND_BASE_URL:-https://api-acc.example.com}"
echo "Running Flutter app (ACC) → $BACKEND_BASE_URL"
flutter run --dart-define=BACKEND_BASE_URL="$BACKEND_BASE_URL"
