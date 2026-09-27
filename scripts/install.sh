#!/bin/bash
# Weiki one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/diegovilloutafredes/Weiki/main/scripts/install.sh | bash
#
# Downloads the latest release, installs it into /Applications, and launches
# it. curl doesn't set the quarantine flag, so Gatekeeper doesn't block the
# ad-hoc-signed app. The README's one-liner fetches this path from main, so
# don't move or rename this file.
set -euo pipefail

APP_NAME="Weiki.app"
APP_DEST="/Applications/$APP_NAME"
ZIP_URL="https://github.com/diegovilloutafredes/Weiki/releases/latest/download/Weiki.zip"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ ! -w /Applications ]; then
    echo "error: /Applications is not writable — run this from an administrator account." >&2
    exit 1
fi

echo "==> Downloading the latest Weiki release..."
curl -fSL --progress-bar -o "$TMP_DIR/Weiki.zip" "$ZIP_URL"

echo "==> Extracting..."
unzip -q "$TMP_DIR/Weiki.zip" -d "$TMP_DIR"

if [ ! -d "$TMP_DIR/$APP_NAME" ]; then
    echo "error: $APP_NAME not found in the downloaded archive." >&2
    exit 1
fi

# Quitting Weiki ends its session. Wait up to 5 s for it to exit, so `open`
# launches the new app instead of reactivating the old one.
if pgrep -xq Weiki; then
    echo "==> Quitting Weiki..."
    pkill -x Weiki || true
    for _ in $(seq 50); do pgrep -xq Weiki || break; sleep 0.1; done
fi

echo "==> Installing into /Applications..."
# Delete, then copy: Launch Services caches an app that is replaced in place.
rm -rf "$APP_DEST"
cp -R "$TMP_DIR/$APP_NAME" "$APP_DEST"

echo "==> Launching..."
open "$APP_DEST"

echo "✓ Weiki is installed. Look for the cup in the menu bar."
