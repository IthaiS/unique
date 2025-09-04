#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"
if [ ! -f "pubspec.yaml" ]; then echo "Run inside foodlabel-ai/mobile"; exit 1; fi
if [ ! -d "android" ] || [ ! -d "ios" ] || [ ! -d "macos" ] || [ ! -d "windows" ]; then
  flutter create .
fi
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q 'android.permission.CAMERA' "$MANIFEST"; then
  # macOS sed: create a .bak and replace closing tag
  sed -i.bak 's#</manifest>#  <uses-permission android:name="android.permission.CAMERA" />\
</manifest>#' "$MANIFEST"
fi
echo "✅ Mobile bootstrap complete."
