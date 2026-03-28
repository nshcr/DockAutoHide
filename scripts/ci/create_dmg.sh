#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ci_require_env "ARCHIVE_PATH"
ci_require_env "APP_NAME"
ci_require_env "RUNNER_TEMP"
ci_require_env "RELEASE_TAG"
ci_require_env "ARCH_LABEL"

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
DIST_DIR="$PWD/dist"
STAGING_DIR="$RUNNER_TEMP/staging-${ARCH_LABEL}"

ci_require_dir "$APP_PATH" "App not found"

mkdir -p "$DIST_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s "/Applications" "$STAGING_DIR/Applications" || true

DMG_PATH="$DIST_DIR/${APP_NAME}-${RELEASE_TAG#v}-${ARCH_LABEL}.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

ci_write_github_env "DMG_PATH" "${DMG_PATH}"
