#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

RELEASE_TAG="${1:-${RELEASE_TAG:-}}"
REPOSITORY="${2:-${GITHUB_REPOSITORY:-}}"

if [[ -z "${RELEASE_TAG}" ]]; then
  ci_usage_with_env "<release-tag> [repository]" "RELEASE_TAG"
  exit 1
fi

if [[ -z "${REPOSITORY}" ]]; then
  echo "Missing GITHUB_REPOSITORY" >&2
  exit 1
fi

gh release view "${RELEASE_TAG}" --repo "${REPOSITORY}" >/dev/null
echo "Verified GitHub release ${REPOSITORY}@${RELEASE_TAG}"
