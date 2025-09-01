#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="."; BRANCH="main"; REMOTE_EXPECTED="https://github.com/IthaiS/unique.git"
while [[ $# -gt 0 ]]; do case "$1" in --repo-root) REPO_ROOT="$2"; shift 2;; --branch) BRANCH="$2"; shift 2;; --remote) REMOTE_EXPECTED="$2"; shift 2;; *) echo "Unknown arg: $1"; exit 1;; esac; done
cd "$REPO_ROOT"; [ -d .git ] || { echo "Not a git repo: $REPO_ROOT"; exit 1; }
REMOTE="$(git remote get-url origin)"; [ -z "$REMOTE_EXPECTED" -o "$REMOTE" = "$REMOTE_EXPECTED" ] || { echo "Remote mismatch: $REMOTE"; exit 1; }
git add .; git commit -m "chore: ingest FoodLabel AI super release (hardened)" || true; git push origin "$BRANCH"; echo "✅ Committed and pushed to $BRANCH"
