#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="." ; BRANCH="main" ; REMOTE_EXPECTED="https://github.com/IthaiS/unique.git"
while [[ $# -gt 0 ]]; do case "$1" in
  --repo-root) REPO_ROOT="$2"; shift 2;;
  --branch) BRANCH="$2"; shift 2;;
  --remote) REMOTE_EXPECTED="$2"; shift 2;;
  *) echo "Unknown arg: $1"; exit 1;; esac; done
cd "$REPO_ROOT"
if [ ! -d .git ]; then echo "Not a git repo: $REPO_ROOT"; exit 1; fi
REMOTE="$(git remote get-url origin)"
if [ -n "$REMOTE_EXPECTED" ] && [ "$REMOTE" != "$REMOTE_EXPECTED" ]; then
  echo "Remote mismatch: $REMOTE"; exit 1
fi
git add .
git commit -m "chore: ingest FoodLabel AI full consolidated pack (v0.9.0)" || true
git push origin "$BRANCH"
echo "✅ Pushed to $BRANCH"
