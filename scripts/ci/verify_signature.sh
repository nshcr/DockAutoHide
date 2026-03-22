#!/usr/bin/env bash
set -euo pipefail

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH"
  exit 1
fi

codesign --verify --deep --strict "$APP_PATH"
