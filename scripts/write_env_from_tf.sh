#!/usr/bin/env bash
set -euo pipefail
STACK_DIR="${STACK_DIR:-foodlabel-ai/infra/stack}"
OUT_FILE="${OUT_FILE:-.env.ci}"
cd "$STACK_DIR"
if ! terraform output -json >/dev/null 2>&1; then echo "❌ No Terraform outputs. Run apply."; exit 1; fi
JSON="$(terraform output -json)"
parse(){ python3 - <<'PY' "$JSON" "$1"
import json,sys;o=json.loads(sys.argv[1]);k=sys.argv[2];print("" if k not in o else ("" if o[k].get("value") is None else str(o[k]["value"])))
PY
}
PID="$(parse project_id)"; REG="$(parse region)"; URL="$(parse cloud_run_url)"
WIF_DEV="$(parse wif_provider_dev_name)"; WIF_PROD="$(parse wif_provider_prod_name)"; WIF_SHARED="$(parse wif_provider_shared_name)"
SA_DEV="$(parse deploy_dev_service_account_email)"; SA_PROD="$(parse deploy_prod_service_account_email)"; SA_SHARED="$(parse deploy_shared_service_account_email)"
if [ -z "$PID" ]; then echo "project_id missing"; exit 1; fi
WIF_DEF="${WIF_SHARED:-${WIF_PROD:-${WIF_DEV}}}"; SA_DEF="${SA_SHARED:-${SA_PROD:-${SA_DEV}}}"
cat > "../${OUT_FILE}" <<EOF
# Generated from Terraform outputs
GCP_PROJECT_ID=${PID}
GCP_REGION=${REG:-europe-west1}
BACKEND_BASE_URL=${URL}
GCP_WORKLOAD_IDENTITY_PROVIDER=${WIF_DEF}
GCP_SERVICE_ACCOUNT_EMAIL=${SA_DEF}
GCP_WIF_PROVIDER_DEV=${WIF_DEV}
GCP_WIF_PROVIDER_PROD=${WIF_PROD}
EOF
echo "✅ Wrote $(cd ..; pwd)/${OUT_FILE}"
