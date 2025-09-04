#!/usr/bin/env bash
set -euo pipefail
files=( backend/api.py backend/assess.py backend/ocr.py backend/Dockerfile 
backend/requirements.txt backend/policies/policy_v1.json 
backend/tests/test_ocr_live.py
        foodlabel-ai/mobile/pubspec.yaml foodlabel-ai/mobile/lib/main.dart 
foodlabel-ai/mobile/lib/src/pages/home_page.dart 
foodlabel-ai/mobile/lib/src/services/ocr_service.dart 
foodlabel-ai/mobile/lib/src/services/assess_service.dart 
foodlabel-ai/mobile/lib/src/services/i18n.dart 
foodlabel-ai/mobile/assets/i18n/en.json 
foodlabel-ai/mobile/assets/i18n/nl_BE.json 
foodlabel-ai/mobile/assets/i18n/fr_BE.json
        foodlabel-ai/infra/stack/main.tf 
foodlabel-ai/infra/stack/outputs.tf foodlabel-ai/infra/stack/versions.tf 
foodlabel-ai/infra/stack/variables.tf
        .github/workflows/infra_stack_apply.yml 
.github/workflows/deploy_backend.yml .github/workflows/flutter_ci.yml 
.github/workflows/backend_ci.yml .github/workflows/android_build.yml 
.github/workflows/sentry_release_versioned.yml )
miss=0; for f in "${files[@]}"; do [ -f "$f" ] || { echo "::error::Missing 
$f"; miss=1; }; done
[ $miss -eq 0 ] && echo "✅ All files present"
exit $miss
