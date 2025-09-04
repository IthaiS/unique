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