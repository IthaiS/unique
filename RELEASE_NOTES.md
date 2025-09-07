## v1.2.0 (Latest)
- Align versions across repo (root VERSION, Flutter pubspec) → 1.2.0.
- Make `policy_v2.json` the canonical assessment policy (default via `POLICY_FILE`, fallback order removed in docs).
- Introduce environment strategy: **Dev / Acc / Prod** with per-env base URLs and secrets.
- Plan Cloud SQL (Postgres) and Secret Manager integration via Terraform; Cloud Run connects using IAM.
- CI/CD updates to target Dev/Acc/Prod using GCP Workload Identity Federation.
- Add `backend/.env.example` and `scripts/write_env_from_tf.sh` usage docs.


# Release Notes

## v1.1.1 (Latest)
- Added desktop OCR support (Windows/macOS) via backend.
- Fixed Terraform WIF provider definitions.
- Added defensive `bootstrap_all.sh` and `bootstrap_mobile.sh`.
- Strengthened `expand_bundles.sh` (no syntax errors).
- Included non-stub README files (docs, repo structure, architecture, setup).
- CI/CD: Infra, backend deploy, mobile build, Sentry integration.

## v1.1.0
- Introduced GitHub Actions pipelines (infra apply, backend deploy, Sentry release).
- Added Slack notification integration.
- Packaged everything into self-contained super release.

## v1.0.0
- Initial MVP: Flutter app + FastAPI backend + Terraform stack.