# Tasks

## 1. App icon

- [x] 1.1 Add `scripts/generate-appicon.swift` per the design, `Weiki/Assets.xcassets` with the `AppIcon.appiconset` contents file, and a `make icon` target. Verify that `make icon` writes all ten PNGs and that the 1024 px one matches the chosen candidate.
- [x] 1.2 Build and install. Verify that the app bundle contains the compiled icon (`AppIcon.icns`, with `CFBundleIconName` set to `AppIcon`) and that macOS shows it for `/Applications/Weiki.app` (checked through `NSWorkspace`, because a Quick Look thumbnail hung).
- [x] 1.3 Add the icon script and the SF Symbols constraint to the project notes. Verify that `openspec validate add-app-icon --strict` succeeds.
