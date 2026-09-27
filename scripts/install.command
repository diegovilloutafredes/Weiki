#!/bin/bash
# Double-click this file in Finder to install Weiki.
# If macOS blocks it ("cannot verify the developer"), run it from Terminal
# instead: bash install.command
set -euo pipefail

APP_NAME="Weiki.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="$SCRIPT_DIR/$APP_NAME"
APP_DEST="/Applications/$APP_NAME"

if [ ! -d "$APP_SRC" ]; then
    osascript -e 'display alert "Installation failed" message "Weiki.app must be in the same folder as this installer." as critical'
    exit 1
fi

# Quitting Weiki ends its session. Wait up to 5 s for it to exit, so `open`
# launches the new app instead of reactivating the old one.
pkill -x Weiki 2>/dev/null || true
for _ in $(seq 50); do pgrep -xq Weiki || break; sleep 0.1; done

# Delete, then copy: Launch Services caches an app that is replaced in place.
rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"

# A browser download carries the quarantine flag, and Gatekeeper blocks an
# ad-hoc-signed app that has it.
xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true

osascript -e 'display notification "Weiki is installed." with title "Installation complete"'

open "$APP_DEST"
