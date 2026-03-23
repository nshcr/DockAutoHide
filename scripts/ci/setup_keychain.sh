#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ci_require_env "RUNNER_TEMP"
ci_require_env "MACOS_CERTIFICATE_PASSWORD"

KEYCHAIN_PASSWORD="${MACOS_KEYCHAIN_PASSWORD:-$(uuidgen)}"
KEYCHAIN_PATH="$RUNNER_TEMP/build.keychain-db"

ci_write_github_env "KEYCHAIN_PATH" "${KEYCHAIN_PATH}"
ci_write_github_env "KEYCHAIN_PASSWORD" "${KEYCHAIN_PASSWORD}"

python3 scripts/ci/write_p12_from_base64.py "$RUNNER_TEMP/cert.p12"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$RUNNER_TEMP/cert.p12" -P "$MACOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security list-keychains -d user -s "$KEYCHAIN_PATH"
security default-keychain -s "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
