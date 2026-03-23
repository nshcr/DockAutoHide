#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ARCH="${1:-${ARCH_LABEL:-}}"

if [[ -z "${ARCH}" ]]; then
  ci_usage_with_env "<arch-label>" "ARCH_LABEL"
  exit 1
fi

case "${ARCH}" in
  arm64) ARCHS="arm64" ;;
  x86_64) ARCHS="x86_64" ;;
  universal) ARCHS="arm64 x86_64" ;;
  *) echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac

ci_write_github_env "ARCHS" "${ARCHS}"
