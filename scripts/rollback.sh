#!/usr/bin/env bash
set -euo pipefail

# Roll back a release:
#  1) Delete local & remote tag
#  2) Reset current branch back N commits (default: 1)
#  3) Push with --force-with-lease
#
# Usage:
#   scripts/rollback.sh <tag> [--commits N] [--remote origin] [--yes] [--dry-run]
#
# Examples:
#   scripts/rollback.sh v1.2.1
#   scripts/rollback.sh v1.2.1 --commits 2 --yes
#   scripts/rollback.sh v1.2.1 --remote upstream --dry-run

usage() {
  echo "Usage: $0 <tag> [--commits N] [--remote origin] [--yes] [--dry-run]"
  exit 1
}

[[ $# -ge 1 ]] || usage

TAG="$1"; shift
COMMITS=1
REMOTE="origin"
YES=0
DRY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commits)
      COMMITS="${2:-}"; shift 2 ;;
    --remote)
      REMOTE="${2:-}"; shift 2 ;;
    --yes|-y)
      YES=1; shift ;;
    --dry-run)
      DRY=1; shift ;;
    -*)
      echo "Unknown option: $1" >&2; usage ;;
    *)
      echo "Unexpected arg: $1" >&2; usage ;;
  esac
done

# Helpers
run() {
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRYRUN: $*"
  else
    eval "$@"
  fi
}

abort() { echo "✖ $*" >&2; exit 1; }

# Basic sanity checks
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || abort "Not inside a git repository."

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" != "HEAD" ]] || abort "You are in a detached HEAD state. Checkout a branch first."

# Ensure working tree is clean
if [[ -n "$(git status --porcelain)" ]]; then
  abort "Working tree not clean. Commit/stash changes first."
fi

# Confirm upstream
if UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)"; then
  UP_REMOTE="${UPSTREAM%%/*}"
  UP_BRANCH="${UPSTREAM#*/}"
  if [[ "$UP_REMOTE" != "$REMOTE" ]]; then
    echo "⚠ Current branch upstream is '$UPSTREAM' but --remote is '$REMOTE'."
  fi
else
  echo "⚠ No upstream configured for branch '$BRANCH'. Push will create/overwrite on $REMOTE."
fi

# Fetch tags so remote checks are accurate
run "git fetch --tags $REMOTE --prune"

# Verify we can reset that far
git rev-parse --verify "HEAD~${COMMITS}" >/dev/null 2>&1 \
  || abort "HEAD~${COMMITS} does not exist. Check --commits value."

# Show what will happen
HEAD_SHA="$(git rev-parse --short HEAD)"
PREV_SHA="$(git rev-parse --short HEAD~${COMMITS})"
echo "About to rollback:"
echo "  • Branch      : $BRANCH"
echo "  • Remote      : $REMOTE"
echo "  • Tag         : $TAG"
echo "  • Reset       : HEAD ($HEAD_SHA)  →  HEAD~${COMMITS} ($PREV_SHA)"
echo "  • Actions     : delete tag (local+remote), hard reset, push --force-with-lease"

if [[ "$YES" -ne 1 && "$DRY" -ne 1 ]]; then
  read -r -p "Proceed? Type 'yes' to continue: " ANSWER
  [[ "$ANSWER" == "yes" ]] || abort "User aborted."
fi

# 1) Delete local tag (if present)
if git show-ref --tags --quiet -- "refs/tags/${TAG}"; then
  run "git tag -d ${TAG}"
else
  echo "ℹ Local tag '${TAG}' not found (skipping local delete)."
fi

# 1b) Delete remote tag (if present)
if git ls-remote --tags "$REMOTE" "refs/tags/${TAG}" | grep -q "refs/tags/${TAG}"; then
  run "git push ${REMOTE} :refs/tags/${TAG}"
else
  echo "ℹ Remote tag '${TAG}' not found on '${REMOTE}' (skipping remote delete)."
fi

# 2) Reset branch back N commits
run "git reset --hard HEAD~${COMMITS}"

# 3) Force push with lease
run "git push --force-with-lease ${REMOTE} ${BRANCH}"

echo "✔ Rollback complete."
