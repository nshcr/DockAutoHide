#!/usr/bin/env bash
set -euo pipefail

KEYCHAIN_PASSWORD="${MACOS_KEYCHAIN_PASSWORD:-$(uuidgen)}"
KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain-db"

{
  echo "KEYCHAIN_PATH=${KEYCHAIN_PATH}"
  echo "KEYCHAIN_PASSWORD=${KEYCHAIN_PASSWORD}"
} >> "${GITHUB_ENV}"

python3 scripts/ci/write_p12_from_base64.py "$RUNNER_TEMP/cert.p12"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$RUNNER_TEMP/cert.p12" -P "$MACOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"
security default-keychain -s "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
