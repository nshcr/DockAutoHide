#!/usr/bin/env bash
set -euo pipefail

ARCH_LABEL="${1:-}"
if [[ -z "${ARCH_LABEL}" ]]; then
  echo "Usage: archive.sh <arch-label>"
  exit 1
fi

ARCHIVE_PATH="$RUNNER_TEMP/${APP_NAME}-${ARCH_LABEL}.xcarchive"

MACOS_SIGNING_IDENTITY="${MACOS_SIGNING_IDENTITY:-}"
MACOS_TEAM_ID="${MACOS_TEAM_ID:-}"

xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$RUNNER_TEMP/DerivedData-${ARCH_LABEL}" \
  ARCHS="$ARCHS" \
  ONLY_ACTIVE_ARCH=NO \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$MACOS_SIGNING_IDENTITY" \
  DEVELOPMENT_TEAM="$MACOS_TEAM_ID" \
  ENABLE_HARDENED_RUNTIME=YES \
  OTHER_CODE_SIGN_FLAGS="--timestamp"

echo "ARCHIVE_PATH=${ARCHIVE_PATH}" >> "${GITHUB_ENV}"
