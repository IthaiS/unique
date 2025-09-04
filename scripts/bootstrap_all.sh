#!/usr/bin/env bash
set -euo pipefail
chmod +x scripts/*.sh || true
chmod +x foodlabel-ai/mobile/scripts/*.sh || true
scripts/expand_bundles.sh
scripts/super_self_check.sh
echo "Next:"
echo "  1) cd foodlabel-ai/infra/stack && terraform init -upgrade && 
terraform apply"
echo "  2) python -m venv .venv && source .venv/bin/activate && pip 
install -r backend/requirements.txt && uvicorn backend.api:app --reload"
echo "  3) flutter run -d macos|windows 
--dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000"
