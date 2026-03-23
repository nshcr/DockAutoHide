#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

missing=()
[[ -z "${MACOS_CERTIFICATE:-}" ]] && missing+=("MACOS_CERTIFICATE")
[[ -z "${MACOS_CERTIFICATE_PASSWORD:-}" ]] && missing+=("MACOS_CERTIFICATE_PASSWORD")
[[ -z "${MACOS_SIGNING_IDENTITY:-}" ]] && missing+=("MACOS_SIGNING_IDENTITY")
[[ -z "${MACOS_TEAM_ID:-}" ]] && missing+=("MACOS_TEAM_ID")

if (( ${#missing[@]} > 0 )); then
  echo "Missing required signing secrets:" >&2
  for item in "${missing[@]}"; do
    echo "  ${item}" >&2
  done
  exit 1
fi
