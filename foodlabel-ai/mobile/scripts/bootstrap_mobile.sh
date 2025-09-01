#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"
if [ ! -f "pubspec.yaml" ]; then echo "Run inside foodlabel-ai/mobile"; exit 1; fi
if [ ! -d "android" ]; then flutter create .; else echo "android/ios already exist — skipping flutter create"; fi
# Android camera permission
MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.CAMERA' "$MANIFEST"; then
  sed -i.bak 's#</manifest>#  <uses-permission android:name="android.permission.CAMERA" />\n</manifest>#' "$MANIFEST"
fi
echo "✅ Mobile bootstrap complete."
