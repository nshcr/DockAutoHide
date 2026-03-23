#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DMG_PATH="${1:-${DMG_PATH:-}}"
if [[ -z "${DMG_PATH}" ]]; then
  ci_usage_with_env "<dmg-path>" "DMG_PATH"
  exit 1
fi

ci_require_env "RUNNER_TEMP"
ci_require_file "${DMG_PATH}" "DMG not found"

missing=()
[[ -z "${APPLE_NOTARIZATION_KEY_ID:-}" ]] && missing+=("APPLE_NOTARIZATION_KEY_ID")
[[ -z "${APPLE_NOTARIZATION_ISSUER_ID:-}" ]] && missing+=("APPLE_NOTARIZATION_ISSUER_ID")
[[ -z "${APPLE_NOTARIZATION_PRIVATE_KEY:-}" ]] && missing+=("APPLE_NOTARIZATION_PRIVATE_KEY")

if (( ${#missing[@]} > 0 )); then
  echo "Missing required notarization secrets:" >&2
  for item in "${missing[@]}"; do
    echo "  ${item}" >&2
  done
  exit 1
fi

KEY_PATH="$RUNNER_TEMP/notarytool-key.p8"
python3 scripts/ci/write_notary_key.py "$KEY_PATH"

xcrun notarytool submit "$DMG_PATH" \
  --key "$KEY_PATH" \
  --key-id "$APPLE_NOTARIZATION_KEY_ID" \
  --issuer "$APPLE_NOTARIZATION_ISSUER_ID" \
  --wait

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
