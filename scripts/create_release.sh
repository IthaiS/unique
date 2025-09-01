#!/usr/bin/env bash
set -euo pipefail
TAG=""; TITLE=""; NOTES=""; ASSET="${1:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2;;
    --title) TITLE="$2"; shift 2;;
    --notes) NOTES="$2"; shift 2;;
    --asset) ASSET="$2"; shift 2;;
    *) shift;;
  esac
done
command -v gh >/dev/null || { echo "Install gh and run 'gh auth login'"; exit 1; }
[[ -n "$TAG" ]] || { echo "Provide --tag vX.Y.Z"; exit 1; }
TITLE_OPT=(); [[ -n "$TITLE" ]] && TITLE_OPT=(--title "$TITLE")
NOTES_OPT=(); [[ -n "$NOTES" && -f "$NOTES" ]] && NOTES_OPT=(--notes-file "$NOTES") || NOTES_OPT=(--notes "Automated release $TAG")
ASSET_OPT=(); [[ -n "$ASSET" && -f "$ASSET" ]] && ASSET_OPT=("$ASSET")
gh release create "$TAG" "${TITLE_OPT[@]}" "${NOTES_OPT[@]}" "${ASSET_OPT[@]}"
