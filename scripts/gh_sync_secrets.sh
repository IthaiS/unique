#!/usr/bin/env bash
set -euo pipefail
ENV_FILE="${1:-.env.ci}"; REPO="${REPO:-IthaiS/unique}"
command -v gh >/dev/null 2>&1 || { echo "Install GitHub CLI and run gh 
auth login"; exit 1; }
[ -f "$ENV_FILE" ] || { echo "$ENV_FILE not found"; exit 1; }
set -a; source <(grep -v "^\s*#" "$ENV_FILE" | sed "/^\s*$/d"); set +a
gh secret set GCP_PROJECT_ID --repo "$REPO" --body "${GCP_PROJECT_ID}"
gh variable set GCP_REGION --repo "$REPO" --body 
"${GCP_REGION:-europe-west1}"
if [[ -n "${BACKEND_BASE_URL:-}" ]]; then gh variable set BACKEND_BASE_URL 
--repo "$REPO" --body "${BACKEND_BASE_URL}"; fi
echo "Synced secrets/vars to $REPO"
