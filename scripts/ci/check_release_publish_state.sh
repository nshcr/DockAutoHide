#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${RELEASE_TAG:-}" ]]; then
  echo "Missing RELEASE_TAG"
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "Missing GITHUB_REPOSITORY"
  exit 1
fi

RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-1}"

if gh release view "$RELEASE_TAG" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  if [[ "$RUN_ATTEMPT" -gt 1 ]]; then
    echo "Release ${GITHUB_REPOSITORY}@${RELEASE_TAG} already exists."
    echo "Allowing rerun attempt ${RUN_ATTEMPT} to continue without recreating or updating the immutable release."
    exit 0
  fi

  echo "Release ${GITHUB_REPOSITORY}@${RELEASE_TAG} already exists."
  echo "Immutable releases forbid republishing the same version. Refusing to start a new build."
  exit 1
fi

echo "No existing release found for ${GITHUB_REPOSITORY}@${RELEASE_TAG}."
