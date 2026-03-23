#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TAP_PATH="${1:-homebrew-tap}"
VERSION="${2:-${MARKETING_VERSION:-}}"
SOURCE_CASK_PATH="${3:-dist/dockautohide.rb}"
TARGET_CASK_PATH="${TAP_PATH}/Casks/dockautohide.rb"

if [[ -z "${VERSION}" ]]; then
  ci_usage_with_env "<tap-path> <version> [source-cask-path]" "MARKETING_VERSION"
  exit 1
fi

ci_require_file "${SOURCE_CASK_PATH}" "Source cask not found"

mkdir -p "${TAP_PATH}/Casks"
cp "${SOURCE_CASK_PATH}" "${TARGET_CASK_PATH}"

cd "${TAP_PATH}"
git add -N "Casks/dockautohide.rb"

if git diff --quiet -- "Casks/dockautohide.rb"; then
  echo "No Homebrew cask changes to publish."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add "Casks/dockautohide.rb"
git commit -m "Update DockAutoHide to ${VERSION}"
git push
