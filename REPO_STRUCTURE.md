# REPO_STRUCTURE (FoodLabel AI)

- VERSION
- backend/
  - Dockerfile, requirements.txt, api.py, assess.py, policies/policy_v1.json, tests/
- foodlabel-ai/mobile/
  - pubspec.yaml, lib/**, assets/i18n/**
  - scripts/bootstrap_mobile.sh (creates platform folders idempotently)
- foodlabel-ai/infra/wif/ (Terraform module for WIF basic)
- foodlabel-ai/infra/stack/ (Terraform extended stack: WIF envs, AR, Cloud Run, Secrets, Firestore opt.)
- .github/workflows/
  - infra_stack_apply.yml, deploy_backend_dev.yml, deploy_backend_prod.yml, deploy_backend.yml,
    sentry_release_versioned.yml, flutter_ci.yml, android_build.yml
- scripts/
  - create_release.sh
- commit_super_release.sh  (universal: unzips & commits)
- Makefile
- docs/ARCHITECTURE.md
- README_SUPER.md
- README_CODE_COMPLETE.md
