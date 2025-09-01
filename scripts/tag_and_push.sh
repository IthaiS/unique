#!/usr/bin/env bash
set -euo pipefail
TAG="${1:-v0.5.0}"
MSG="${2:-Release $TAG}"
# Ensure clean worktree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Uncommitted changes present. Commit or stash before tagging." >&2
  exit 1
fi
git tag -a "$TAG" -m "$MSG"
git push origin "$TAG"
echo "✅ Pushed tag $TAG"
