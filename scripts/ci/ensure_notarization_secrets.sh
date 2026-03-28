#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

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
