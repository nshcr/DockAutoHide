#!/usr/bin/env bash
set -euo pipefail

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
DIST_DIR="$PWD/dist"
STAGING_DIR="$RUNNER_TEMP/staging-${ARCH_LABEL:-unknown}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH"
  exit 1
fi

mkdir -p "$DIST_DIR"
mkdir -p "$STAGING_DIR"

ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s "/Applications" "$STAGING_DIR/Applications" || true

DMG_PATH="$DIST_DIR/${APP_NAME}-${RELEASE_TAG#v}-${ARCH_LABEL}.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

echo "DMG_PATH=${DMG_PATH}" >> "${GITHUB_ENV}"
