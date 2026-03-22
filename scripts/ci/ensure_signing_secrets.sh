#!/usr/bin/env bash
set -euo pipefail

missing=()
[[ -z "${MACOS_CERTIFICATE:-}" ]] && missing+=("MACOS_CERTIFICATE")
[[ -z "${MACOS_CERTIFICATE_PASSWORD:-}" ]] && missing+=("MACOS_CERTIFICATE_PASSWORD")
[[ -z "${MACOS_SIGNING_IDENTITY:-}" ]] && missing+=("MACOS_SIGNING_IDENTITY")
[[ -z "${MACOS_TEAM_ID:-}" ]] && missing+=("MACOS_TEAM_ID")

if (( ${#missing[@]} > 0 )); then
  echo "Missing one or more signing secrets:"
  for item in "${missing[@]}"; do
    echo "  ${item}"
  done
  exit 1
fi
