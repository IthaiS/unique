#!/usr/bin/env bash
set -euo pipefail

# If no matching files, don't expand the literal pattern
shopt -s nullglob

if compgen -G "bundles/*.zip" >/dev/null; then
  for z in bundles/*.zip; do
    unzip -o "$z" >/dev/null
  done
  echo "Bundles expanded."
else
  echo "No child bundles found; skipping."
fi

exit 0
