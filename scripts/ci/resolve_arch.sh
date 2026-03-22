#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-}"

case "${ARCH}" in
  arm64) ARCHS="arm64" ;;
  x86_64) ARCHS="x86_64" ;;
  universal) ARCHS="arm64 x86_64" ;;
  *) echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac

echo "ARCHS=${ARCHS}" >> "${GITHUB_ENV}"
