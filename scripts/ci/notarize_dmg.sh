#!/usr/bin/env bash
set -euo pipefail

DMG_PATH="${1:-}"
if [[ -z "${DMG_PATH}" ]]; then
  echo "Usage: notarize_dmg.sh <dmg-path>"
  exit 1
fi

missing=()
[[ -z "${APPLE_NOTARIZATION_KEY_ID:-}" ]] && missing+=("APPLE_NOTARIZATION_KEY_ID")
[[ -z "${APPLE_NOTARIZATION_ISSUER_ID:-}" ]] && missing+=("APPLE_NOTARIZATION_ISSUER_ID")
[[ -z "${APPLE_NOTARIZATION_PRIVATE_KEY:-}" ]] && missing+=("APPLE_NOTARIZATION_PRIVATE_KEY")

if (( ${#missing[@]} > 0 )); then
  echo "Missing notarization secrets:"
  for item in "${missing[@]}"; do
    echo "  ${item}"
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
