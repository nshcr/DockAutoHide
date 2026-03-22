#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="${1:-}"
if [[ -z "${DMG_PATH}" ]]; then
  echo "Usage: create_dmg_checksum.sh <dmg-path>"
  exit 1
fi

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
