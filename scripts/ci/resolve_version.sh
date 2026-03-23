#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

MARKETING_VERSION_INPUT="${MARKETING_VERSION_INPUT:-}"

if [[ "${GITHUB_EVENT_NAME}" == "workflow_dispatch" ]]; then
  if [[ -z "${MARKETING_VERSION_INPUT}" ]]; then
    echo "workflow_dispatch requires MARKETING_VERSION_INPUT"
    exit 1
  fi
  MARKETING_VERSION="${MARKETING_VERSION_INPUT}"
  RELEASE_TAG="v${MARKETING_VERSION}"
else
  RELEASE_TAG="${GITHUB_REF_NAME:-}"
  MARKETING_VERSION="${RELEASE_TAG#v}"
fi

if [[ -z "${RELEASE_TAG}" ]]; then
  echo "Missing RELEASE_TAG" >&2
  exit 1
fi

if [[ ! "${RELEASE_TAG}" =~ ^v.+$ ]]; then
  echo "Invalid tag format: ${RELEASE_TAG}" >&2
  exit 1
fi

if [[ ! "${MARKETING_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid MARKETING_VERSION: ${MARKETING_VERSION}" >&2
  echo "Expected SemVer without build metadata. Example: 1.2.3 or 1.2.3-beta.1" >&2
  exit 1
fi

ci_write_github_env "MARKETING_VERSION" "${MARKETING_VERSION}"
ci_write_github_env "RELEASE_TAG" "${RELEASE_TAG}"
