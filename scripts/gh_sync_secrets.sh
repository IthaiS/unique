#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="${1:-.env.ci}"; REPO="${REPO:-IthaiS/unique}"
if ! command -v gh >/dev/null 2>&1; then echo "Install GitHub CLI and run 'gh auth login'"; exit 1; fi
if [ ! -f "$ENV_FILE" ]; then echo "$ENV_FILE not found. Run write_env_from_tf.sh first."; exit 1; fi
set -a; source <(grep -v '^\s*#' "$ENV_FILE" | sed '/^\s*$/d'); set +a
: "${GCP_PROJECT_ID:?Missing GCP_PROJECT_ID in $ENV_FILE}"
: "${GCP_WORKLOAD_IDENTITY_PROVIDER:?Missing GCP_WORKLOAD_IDENTITY_PROVIDER in $ENV_FILE}"
gh secret set GCP_PROJECT_ID --repo "$REPO" --body "${GCP_PROJECT_ID}"
gh secret set GCP_WORKLOAD_IDENTITY_PROVIDER --repo "$REPO" --body "${GCP_WORKLOAD_IDENTITY_PROVIDER}"
gh secret set GCP_SERVICE_ACCOUNT_EMAIL --repo "$REPO" --body "${GCP_SERVICE_ACCOUNT_EMAIL:-}"
gh secret set GCP_WIF_PROVIDER_DEV --repo "$REPO" --body "${GCP_WIF_PROVIDER_DEV:-}"
gh secret set GCP_WIF_PROVIDER_PROD --repo "$REPO" --body "${GCP_WIF_PROVIDER_PROD:-}"
gh variable set GCP_REGION --repo "$REPO" --body "${GCP_REGION:-europe-west1}"
gh variable set CLOUD_RUN_SERVICE --repo "$REPO" --body "${CLOUD_RUN_SERVICE:-foodlabel-backend}"
if [[ -n "${BACKEND_BASE_URL:-}" ]]; then gh variable set BACKEND_BASE_URL --repo "$REPO" --body "${BACKEND_BASE_URL}"; fi
echo "✅ Synced secrets/vars to $REPO"
