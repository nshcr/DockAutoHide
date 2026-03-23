#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ci_require_env "ARCHIVE_PATH"
ci_require_env "APP_NAME"

APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_NAME.app"
ci_require_dir "$APP_PATH" "App not found"

codesign --verify --deep --strict "$APP_PATH"
