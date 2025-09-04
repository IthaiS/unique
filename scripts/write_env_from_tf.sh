#!/usr/bin/env bash
set -euo pipefail
STACK_DIR="foodlabel-ai/infra/stack"
OUT_FILE=".env.ci"
cd "$STACK_DIR"
if ! terraform output -json >/dev/null 2>&1; then echo "No Terraform 
outputs; run apply first."; exit 1; fi
JSON="$(terraform output -json)"
parse(){ python3 - <<'PY' "$JSON" "$1"
import json,sys;o=json.loads(sys.argv[1]);k=sys.argv[2];print("" if k not 
in o else ("" if o[k].get("value") is None else str(o[k]["value"])))
PY
}
PID=$(parse project_id); REG=$(parse region); URL=$(parse cloud_run_url)
cd - >/dev/null
cat > "${OUT_FILE}" <<EOF
GCP_PROJECT_ID=${PID}
GCP_REGION=${REG}
BACKEND_BASE_URL=${URL}
EOF
echo "Wrote ${OUT_FILE}"
