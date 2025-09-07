#!/usr/bin/env bash
set -euo pipefail

echo "🧹 Cleaning Terraform artifacts..."
find . -type f \
  \( -name '*.tfplan' -o -name '*.tfplan.*' -o -name 'destroy.*.tfplan' -o -name 'plan.*.log' -o -name '*.tfstate.backup' \) \
  -print -delete
echo "✔ Cleanup complete!"
