#!/usr/bin/env bash
set -euo pipefail
ROOT="$(pwd)"
BUNDLES_DIR="${1:-bundles}"
if [ ! -d "$BUNDLES_DIR" ]; then echo "❌ bundles dir not found"; exit 1; fi
for z in mobile_bundle.zip backend_bundle.zip infra_bundle.zip workflows_bundle.zip docs_bundle.zip; do
  if [ -f "$BUNDLES_DIR/$z" ]; then
    echo "📦 Extracting $z"
    unzip -o "$BUNDLES_DIR/$z" -d "$ROOT" >/dev/null
  else
    echo "⚠️  Missing $z — skipping"
  fi
done
echo "✅ Bundles extracted."
