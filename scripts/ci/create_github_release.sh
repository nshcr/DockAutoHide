#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

RELEASE_FILES=(
  dist/*.dmg
  dist/*.dmg.sha256
  dist/checksums.txt
)

ci_require_env "RELEASE_TAG"
ci_require_env "GITHUB_REPOSITORY"

for release_file in "${RELEASE_FILES[@]}"; do
  ci_require_file "${release_file}" "Release artifact not found"
done

if gh release view "$RELEASE_TAG" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  echo "Release ${GITHUB_REPOSITORY}@${RELEASE_TAG} already exists. Verifying assets and preserving immutability."

  release_assets="$(
    gh release view "$RELEASE_TAG" \
      --repo "$GITHUB_REPOSITORY" \
      --json assets \
      --jq '.assets[].name'
  )"

  missing_assets=()
  for release_file in "${RELEASE_FILES[@]}"; do
    asset_name="$(basename "$release_file")"
    if ! grep -Fqx "$asset_name" <<<"$release_assets"; then
      missing_assets+=("$asset_name")
    fi
  done

  if [[ "${#missing_assets[@]}" -gt 0 ]]; then
    printf 'Release exists but is missing required assets:\n' >&2
    printf '  %s\n' "${missing_assets[@]}" >&2
    echo "Immutable releases cannot be updated automatically. Resolve the incomplete release manually before rerunning." >&2
    exit 1
  fi

  echo "All required release assets already exist. Skipping release creation."
  exit 0
fi

gh release create \
  "$RELEASE_TAG" \
  "${RELEASE_FILES[@]}" \
  --repo "$GITHUB_REPOSITORY" \
  --generate-notes \
  --target "$GITHUB_SHA"
