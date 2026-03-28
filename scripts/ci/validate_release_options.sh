#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SIGN_INPUT="${SIGN_INPUT:-true}"
NOTARIZE_INPUT="${NOTARIZE_INPUT:-false}"

if [[ "${NOTARIZE_INPUT}" == "true" && "${SIGN_INPUT}" != "true" ]]; then
  echo "Notarization requires signing. Set sign=true when notarize=true." >&2
  exit 1
fi
