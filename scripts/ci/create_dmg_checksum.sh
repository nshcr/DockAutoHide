#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DMG_PATH="${1:-${DMG_PATH:-}}"
if [[ -z "${DMG_PATH}" ]]; then
  ci_usage_with_env "<dmg-path>" "DMG_PATH"
  exit 1
fi

ci_require_file "${DMG_PATH}" "DMG not found"

shasum -a 256 "$DMG_PATH" > "$DMG_PATH.sha256"
