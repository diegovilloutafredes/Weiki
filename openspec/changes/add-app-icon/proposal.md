# Proposal

## Why

Weiki shows the generic app icon in Finder, Spotlight, Activity Monitor, and System Settings > Login Items. A recognizable icon makes it easy to find and tells people what it is.

## What Changes

- An app icon: an amber cup with a saucer and three wisps of steam on a deep-navy rounded square ("Night shift", chosen from three rendered candidates).
- A script that draws the icon into every size of the app's icon set, and a `make icon` target that runs it.

## Capabilities

### New Capabilities

None. The icon is visual identity, not behavior, so this change has no spec deltas (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- **Files:** `scripts/generate-appicon.swift`, `Weiki/Assets.xcassets/` (the icon set), and the `Makefile`.
- **Build:** the project already names `AppIcon` as its app icon, so no build settings change.
