#!/usr/bin/env bash
set -euo pipefail
echo "🔧 FoodLabel AI bootstrap starting..."
chmod +x scripts/*.sh || true
chmod +x foodlabel-ai/mobile/scripts/*.sh || true
./scripts/expand_bundles.sh || { echo "❌ expand_bundles failed"; exit 1; }
./scripts/super_self_check.sh || { echo "❌ self-check failed"; exit 1; }
echo
echo "✅ Bootstrap complete. Next steps:"
echo "  cd foodlabel-ai/infra/stack && terraform init -upgrade && terraform apply"
echo "  cd ../../.. && ./scripts/write_env_from_tf.sh && REPO=IthaiS/unique ./scripts/gh_sync_secrets.sh .env.ci"
echo "  cd foodlabel-ai/mobile && ./scripts/bootstrap_mobile.sh && flutter pub get && flutter test"
