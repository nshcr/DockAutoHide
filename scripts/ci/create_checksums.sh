#!/usr/bin/env bash
set -euo pipefail

if ! ls dist/*.dmg >/dev/null 2>&1; then
  echo "No DMG files found in dist/"
  exit 1
fi

shasum -a 256 dist/*.dmg > dist/checksums.txt
cat dist/checksums.txt
