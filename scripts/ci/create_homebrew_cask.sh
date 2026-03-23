#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-${MARKETING_VERSION:-}}"
OUTPUT_PATH="${2:-dist/dockautohide.rb}"

if [[ -z "${VERSION}" ]]; then
  echo "Usage: create_homebrew_cask.sh <version> [output-path]"
  echo "Or set MARKETING_VERSION in the environment."
  exit 1
fi

SHA_FILE="dist/DockAutoHide-${VERSION}-universal.dmg.sha256"
if [[ ! -f "${SHA_FILE}" ]]; then
  echo "Missing checksum file: ${SHA_FILE}"
  exit 1
fi

SHA256="$(awk '{print $1}' "${SHA_FILE}")"

mkdir -p "$(dirname "${OUTPUT_PATH}")"

cat > "${OUTPUT_PATH}" <<EOF
cask "dockautohide" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/nshcr/DockAutoHide/releases/download/v#{version}/DockAutoHide-#{version}-universal.dmg"
  name "DockAutoHide"
  desc "Auto-hide the Dock only when a window would cover it"
  homepage "https://github.com/nshcr/DockAutoHide"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "DockAutoHide.app"

  zap trash: [
    "~/Library/Preferences/io.github.nshcr.DockAutoHide.plist",
    "~/Library/Saved Application State/io.github.nshcr.DockAutoHide.savedState",
  ]
end
EOF

echo "Generated Homebrew Cask at ${OUTPUT_PATH}"
