#!/usr/bin/env bash
set -euo pipefail

RELEASE_FILES=(
  dist/*.dmg
  dist/*.dmg.sha256
  dist/checksums.txt
)

if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
  gh release upload "$RELEASE_TAG" "${RELEASE_FILES[@]}" --clobber
else
  gh release create "$RELEASE_TAG" "${RELEASE_FILES[@]}" --generate-notes --target "$GITHUB_SHA"
fi
