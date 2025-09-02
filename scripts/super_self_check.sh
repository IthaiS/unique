#!/usr/bin/env bash
set -euo pipefail
REQ=( backend/api.py backend/assess.py backend/Dockerfile backend/requirements.txt backend/tests/test_assess.py
      foodlabel-ai/mobile/pubspec.yaml foodlabel-ai/mobile/lib/main.dart foodlabel-ai/mobile/lib/src/pages/home_page.dart
      foodlabel-ai/mobile/lib/src/services/ocr_service.dart foodlabel-ai/mobile/lib/src/services/assess_service.dart foodlabel-ai/mobile/lib/src/services/i18n.dart
      foodlabel-ai/mobile/assets/i18n/en.json foodlabel-ai/mobile/assets/i18n/nl_BE.json foodlabel-ai/mobile/assets/i18n/fr_BE.json
      foodlabel-ai/infra/stack/main.tf foodlabel-ai/infra/stack/outputs.tf .github/workflows/infra_stack_apply.yml )
missing=0
for f in "${REQ[@]}"; do
  if [ ! -f "$f" ]; then echo "::error::Missing $f"; missing=1; fi
done
[ $missing -eq 0 ] && echo "✅ All required files present"
exit $missing
