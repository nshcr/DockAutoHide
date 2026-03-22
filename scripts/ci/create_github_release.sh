#!/usr/bin/env bash
set -euo pipefail

if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
  gh release upload "$RELEASE_TAG" dist/* --clobber
else
  gh release create "$RELEASE_TAG" dist/* --generate-notes --target "$GITHUB_SHA"
fi
