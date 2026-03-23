#!/usr/bin/env bash
set -euo pipefail

TAP_PATH="${1:-homebrew-tap}"
VERSION="${2:-${MARKETING_VERSION:-}}"
SOURCE_CASK_PATH="${3:-dist/dockautohide.rb}"
TARGET_CASK_PATH="${TAP_PATH}/Casks/dockautohide.rb"

if [[ -z "${VERSION}" ]]; then
  echo "Usage: update_homebrew_tap.sh <tap-path> <version> [source-cask-path]"
  echo "Or set MARKETING_VERSION in the environment."
  exit 1
fi

if [[ ! -f "${SOURCE_CASK_PATH}" ]]; then
  echo "Source cask not found: ${SOURCE_CASK_PATH}"
  exit 1
fi

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
