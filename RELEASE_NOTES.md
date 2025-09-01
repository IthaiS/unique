# FoodLabel AI v0.5.0 — Release Notes

## 🚀 Highlights
- **Mobile App (Flutter)**
  - OCR scanning with Google ML Kit
  - Ingredient extraction + AI-based assessment
  - Localization for English, Dutch (BE), French (BE)
  - Tests included (`flutter test`)

- **Backend (FastAPI)**
  - Assessment API `/v1/assess`
  - Policy-based scoring (allergens, additives, vegan conflicts)
  - Dockerized for Cloud Run
  - Unit tests included (`pytest`)

- **Infrastructure (Terraform)**
  - Workload Identity Federation (WIF) for GitHub Actions
  - Extended stack with Artifact Registry, Cloud Run, Secret Manager, optional Firestore
  - Idempotent, environment-specific (dev/prod) setup

- **CI/CD (GitHub Actions)**
  - Infra plan/apply (`infra_stack_apply.yml`)
  - Backend deploy (dev/prod/manual)
  - Sentry release automation
  - Flutter CI (analyze + test)
  - Android build workflow (debug APK artifact)

- **Developer Experience**
  - `Makefile` with shortcuts (`make commit`, `make infra`, `make deploy-dev`, `make deploy-prod`, `make release`)
  - `commit_super_release.sh` helper
  - `scripts/create_release.sh` GitHub Release automation
  - Architecture diagrams (Mermaid)

## 🧪 Tests
- Backend: `pytest backend/tests/`
- Mobile: `flutter test foodlabel-ai/mobile/test/`

## ⚡ Getting Started
1. Configure repo variables/secrets (see `README_SUPER.md`)
2. Run infra stack once (Terraform)
3. Push to `develop` or `main` to deploy
4. Bootstrap mobile app and run on device

## ✅ Version
This release sets the repo version to **0.5.0**.
