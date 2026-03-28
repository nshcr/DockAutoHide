#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ARCH_LABEL="${1:-${ARCH_LABEL:-}}"
if [[ -z "${ARCH_LABEL}" ]]; then
  ci_usage_with_env "<arch-label>" "ARCH_LABEL"
  exit 1
fi

ci_require_env "APP_NAME"
ci_require_env "PROJECT"
ci_require_env "SCHEME"
ci_require_env "RUNNER_TEMP"
ci_require_env "ARCHS"
ci_require_env "BUILD_NUMBER"
ci_require_env "MARKETING_VERSION"

ARCHIVE_PATH="$RUNNER_TEMP/${APP_NAME}-${ARCH_LABEL}.xcarchive"

MACOS_SIGNING_IDENTITY="${MACOS_SIGNING_IDENTITY:-}"
MACOS_TEAM_ID="${MACOS_TEAM_ID:-}"

XCODEBUILD_ARGS=(
  archive
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration Release
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  -derivedDataPath "$RUNNER_TEMP/DerivedData-${ARCH_LABEL}"
  ARCHS="$ARCHS"
  ONLY_ACTIVE_ARCH=NO
  SKIP_INSTALL=NO
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
  MARKETING_VERSION="$MARKETING_VERSION"
)

if [[ -n "$MACOS_SIGNING_IDENTITY" && -n "$MACOS_TEAM_ID" ]]; then
  XCODEBUILD_ARGS+=(
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="$MACOS_SIGNING_IDENTITY"
    DEVELOPMENT_TEAM="$MACOS_TEAM_ID"
    ENABLE_HARDENED_RUNTIME=YES
    OTHER_CODE_SIGN_FLAGS="--timestamp"
  )
else
  XCODEBUILD_ARGS+=(
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGNING_REQUIRED=NO
  )
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

ci_write_github_env "ARCHIVE_PATH" "${ARCHIVE_PATH}"
