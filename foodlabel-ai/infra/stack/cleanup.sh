#!/usr/bin/env bash
# cleanup.sh
# Removes local Terraform plan/state/log clutter

set -euo pipefail

echo "🧹 Cleaning Terraform artifacts..."

# Remove plan files
find . -type f -name "*.tfplan" -print -delete
find . -type f -name "*.tfplan.*" -print -delete
find . -type f -name "destroy.*.tfplan" -print -delete
find . -type f -name "plan.*.log" -print -delete

# Remove backup state files (not the real state if using remote backend)
find . -type f -name "*.tfstate.backup" -print -delete

echo "✔ Cleanup complete!"
