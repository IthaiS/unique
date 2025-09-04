# Security Hardening

## Identity & Access
- Use **Workload Identity Federation**: no JSON keys in GitHub.
- Separate deployer & runtime service accounts.
- Grant **least privilege** IAM roles only.

## Infrastructure
- Artifact Registry for Docker images (no Docker Hub).
- Cloud Run services locked down if possible (restrict ingress).
- Enable logging/monitoring (Cloud Logging, Cloud Monitoring).

## Secrets
- Store Slack/Sentry tokens in **GitHub Secrets** only.
- Never commit `.env` or Terraform state.
- Example secrets:
  - `GCP_PROJECT_ID`
  - `GCP_WORKLOAD_IDENTITY_PROVIDER`
  - `GCP_SERVICE_ACCOUNT_EMAIL`
  - `SLACK_WEBHOOK_URL`
  - `SENTRY_AUTH_TOKEN`

## CI/CD
- Pin all GitHub Action versions.
- Use branch protections (require CI before merge).
- Run `terraform plan` with review before `apply` in prod.