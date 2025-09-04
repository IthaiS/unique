# FoodLabel AI – Super Bundle v1.1.1

This repository contains the **entire system** for FoodLabel AI:
- **Flutter mobile/desktop app** (OCR via ML Kit on Android/iOS, backend OCR via Cloud Vision on Windows/macOS).
- **FastAPI backend** with `/v1/ocr` (Google Vision API) and `/v1/assess` (ingredient analysis).
- **Infrastructure as Code** (Terraform) to set up GCP Workload Identity Federation, Cloud Run, Artifact Registry, and Vision API.
- **GitHub Actions workflows** for CI/CD, infra management, Sentry, and Slack notifications.
- **Scripts** to bootstrap, sync GitHub secrets, expand bundles, and validate presence of critical files.
- **Documentation** with setup guides, architecture diagrams, repo structure, and security hardening.

---

## Quick Start

```bash
# Generate full repo locally
bash make_foodlabel_ai_super_release_v1_1_1.sh

# Bootstrap all scripts and run a self-check
cd foodlabel-ai-super-v1.1.1
bash scripts/bootstrap_all.sh