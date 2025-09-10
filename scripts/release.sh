#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/release.sh 1.2.1 "Test fixes (backend & frontend)"
# Requires: git, awk/sed, and optionally GitHub CLI (gh) if you want the GH Release.

VER="${1:-}"
MSG="${2:-}"
if [[ -z "$VER" ]]; then
  echo "Usage: $0 <version> [message]"; exit 1
fi
if ! [[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must be semver like 1.2.1"; exit 1
fi

# Safety checks
git diff --quiet || { echo "✖ Working tree not clean. Commit or stash first."; exit 1; }
git fetch -p
CURR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURR_BRANCH" != "main" && "$CURR_BRANCH" != "develop" ]]; then
  echo "⚠ Releasing from '$CURR_BRANCH'. Continue? [y/N]"
  read -r ans; [[ "${ans,,}" == "y" ]] || exit 1
fi

# 1) Bump versions where your project expects them
# Root VERSION file (used by workflows like sentry_release_versioned.yml)
echo "$VER" > VERSION

# Flutter pubspec.yaml
if [[ -f foodlabel-ai/mobile/pubspec.yaml ]]; then
  sed -E -i.bak "s/^version: .*/version: ${VER}+1/" foodlabel-ai/mobile/pubspec.yaml
  rm -f foodlabel-ai/mobile/pubspec.yaml.bak
fi

# (Optional) backend version file, if you keep one (uncomment if applicable)
# echo "__version__ = \"${VER}\"" > backend/version.py

# 2) Update CHANGELOG.md (very basic append; adjust to your style)
DATE="$(date +%Y-%m-%d)"
if [[ -f CHANGELOG.md ]]; then
  awk -v ver="$VER" -v date="$DATE" '
    BEGIN { added=0 }
    /^## \[Unreleased\]/ && !added {
      print;
      print "";
      print "## [" ver "] - " date;
      print "- '"${MSG:-Release}"'";
      added=1;
      next
    }
    { print }
  ' CHANGELOG.md > CHANGELOG.md.new && mv CHANGELOG.md.new CHANGELOG.md
else
  cat > CHANGELOG.md <<EOF
# Changelog

## [Unreleased]

## [${VER}] - ${DATE}
- ${MSG:-Release}
EOF
fi

# 3) Commit
git add VERSION CHANGELOG.md || true
git add foodlabel-ai/mobile/pubspec.yaml || true
# git add backend/version.py || true
git commit -m "release: v${VER} — ${MSG:-No details}"

# 4) Tag
git tag -a "v${VER}" -m "Release v${VER}"

# 5) Push branch + tag (triggers CI + Sentry release workflow on tag)
git push origin "${CURR_BRANCH}"
git push origin "v${VER}"

# 6) (Optional) Create a GitHub Release from the tag (will attach notes from CHANGELOG if you want)
if command -v gh >/dev/null 2>&1; then
  echo "Create GitHub Release now? [y/N]"
  read -r rel
  if [[ "${rel,,}" == "y" ]]; then
    # Pull notes for this version from CHANGELOG (very simple; customize as needed)
    NOTES=$(awk -v ver="$VER" '
      $0 ~ "^## \\[" ver "\\]" {print_flag=1; next}
      print_flag && $0 ~ "^## \\[" {print_flag=0}
      print_flag {print}
    ' CHANGELOG.md)
    gh release create "v${VER}" --title "v${VER}" --notes "${NOTES:-Release ${VER}}"
  fi
fi

echo "✅ Release v${VER} created, pushed, and tagged."
echo "   – CI for main/develop will run (flutter_ci, backend_ci)."
echo "   – Tag push triggers: Sentry Release (versioned)."
