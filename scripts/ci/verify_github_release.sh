#!/usr/bin/env bash
set -euo pipefail

RELEASE_TAG="${1:-${RELEASE_TAG:-}}"
REPOSITORY="${2:-${GITHUB_REPOSITORY:-}}"

if [[ -z "${RELEASE_TAG}" ]]; then
  echo "Usage: verify_github_release.sh <release-tag> [repository]"
  echo "Or set RELEASE_TAG in the environment."
  exit 1
fi

if [[ -z "${REPOSITORY}" ]]; then
  echo "Missing repository. Pass it as the second argument or set GITHUB_REPOSITORY."
  exit 1
fi

gh release view "${RELEASE_TAG}" --repo "${REPOSITORY}" >/dev/null
echo "Verified GitHub release ${REPOSITORY}@${RELEASE_TAG}"
