# Design

## Context

See `proposal.md`. The author's other menu bar app draws its icon with a Swift script: Core Graphics shapes on a 100-unit grid, a rounded-square background, and one PNG written for each size of the icon set. Weiki reuses that approach.

## Goals / Non-Goals

**Goals:**
- An icon that reads clearly from 16 px up to 1024 px.
- Regenerating every size takes one command.

**Non-Goals:**
- A layered icon for macOS's newer icon format. A classic icon set is enough for now.

## Decisions

### 1. The cup is drawn with paths, not an SF Symbol
Apple's SF Symbols license doesn't allow symbols in app icons. So the cup, saucer, and steam are Core Graphics paths: a tapered cup body, a half-ring handle, a rounded saucer bar, and three S-curves of steam. They resemble the menu bar's `cup.and.saucer` without copying it.

### 2. Palette
The background is a vertical gradient from `#2E3F6E` to `#121930` inside a rounded square (82 of 100 units, corner radius 19). The cup, handle, and saucer are amber `#F6B94C`, and the steam is white at 60% opacity.

### 3. Small sizes
At 16 and 32 px, the steam stroke is thicker so the wisps don't disappear.

### 4. Tooling
`scripts/generate-appicon.swift` writes the ten PNGs named in `AppIcon.appiconset/Contents.json`. `make icon` runs it with `xcrun swift`, because the swiftly `swift` on PATH fails against the Xcode SDK.

## Risks / Trade-offs

- **On recent macOS, icons that don't follow the rounded-square grid can get a system background plate.** → The icon uses the standard 82-unit rounded square, like the other app's icon.
