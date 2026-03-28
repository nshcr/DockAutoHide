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
SUBMISSION_ID_PATH="$RUNNER_TEMP/notary-submission-id.txt"
SUBMISSION_JSON_PATH="$RUNNER_TEMP/notary-submission.json"
python3 scripts/ci/write_notary_key.py "$KEY_PATH"
chmod 600 "$KEY_PATH"

hdiutil verify "$DMG_PATH"

cleanup() {
  rm -f "$KEY_PATH" "$SUBMISSION_ID_PATH" "$SUBMISSION_JSON_PATH"
}

print_notary_log() {
  if [[ -f "$SUBMISSION_ID_PATH" ]]; then
    submission_id="$(cat "$SUBMISSION_ID_PATH")"
    if [[ -n "$submission_id" ]]; then
      echo "Fetching notarization log for submission ${submission_id}..." >&2
      xcrun notarytool log "$submission_id" \
        --key "$KEY_PATH" \
        --key-id "$APPLE_NOTARIZATION_KEY_ID" \
        --issuer "$APPLE_NOTARIZATION_ISSUER_ID" || true
    fi
  fi
}

trap cleanup EXIT

if ! xcrun notarytool submit "$DMG_PATH" \
    --key "$KEY_PATH" \
    --key-id "$APPLE_NOTARIZATION_KEY_ID" \
    --issuer "$APPLE_NOTARIZATION_ISSUER_ID" \
    --wait \
    --output-format json >"$SUBMISSION_JSON_PATH"; then
  if [[ -s "$SUBMISSION_JSON_PATH" ]]; then
    python3 - "$SUBMISSION_JSON_PATH" "$SUBMISSION_ID_PATH" <<'PY'
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text())
submission_id = payload.get("id")
if submission_id:
    pathlib.Path(sys.argv[2]).write_text(submission_id)
PY
  fi
  print_notary_log
  exit 1
fi

submission_id="$(python3 -c 'import json, pathlib, sys; print(json.loads(pathlib.Path(sys.argv[1]).read_text())["id"])' "$SUBMISSION_JSON_PATH")"
printf '%s' "$submission_id" > "$SUBMISSION_ID_PATH"

xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"
