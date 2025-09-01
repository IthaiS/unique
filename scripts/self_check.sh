#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
REQUIRED=(
  "VERSION"
  "README_SUPER.md"
  "RELEASE_NOTES.md"
  "backend/api.py"
  "backend/assess.py"
  "backend/requirements.txt"
  "backend/Dockerfile"
  "backend/tests/test_assess.py"
  "foodlabel-ai/mobile/pubspec.yaml"
  "foodlabel-ai/mobile/lib/main.dart"
  "foodlabel-ai/mobile/lib/src/pages/home_page.dart"
  "foodlabel-ai/mobile/lib/src/services/ocr_service.dart"
  "foodlabel-ai/mobile/lib/src/services/assess_service.dart"
  "foodlabel-ai/mobile/lib/src/services/i18n.dart"
  "foodlabel-ai/mobile/assets/i18n/en.json"
  "foodlabel-ai/mobile/assets/i18n/nl_BE.json"
  "foodlabel-ai/mobile/assets/i18n/fr_BE.json"
  "foodlabel-ai/infra/wif/main.tf"
  "foodlabel-ai/infra/stack/main.tf"
  ".github/workflows/infra_stack_apply.yml"
  ".github/workflows/deploy_backend_dev.yml"
  ".github/workflows/deploy_backend_prod.yml"
  ".github/workflows/deploy_backend.yml"
  ".github/workflows/sentry_release_versioned.yml"
  ".github/workflows/flutter_ci.yml"
  ".github/workflows/android_build.yml"
  ".github/workflows/backend_ci.yml"
)
for f in "${REQUIRED[@]}"; do
  if [ ! -f "$ROOT/$f" ]; then echo "::error::Missing $f"; exit 1; fi
done
echo "✅ All required files present."
