# Proposal

## Why

Right now the only way to install Weiki is to build it from source, which needs Xcode and XcodeGen. Publishing versioned releases on GitHub, as the author's other menu bar app does, lets anyone install Weiki with one command or a download, and gives every version a tag.

## What Changes

- `make tag VERSION=x.y.z` cuts a release. It checks the version, the branch, and a clean working tree, runs the tests, sets `MARKETING_VERSION` in `project.yml` and commits the bump, creates the annotated tag `vx.y.z`, and pushes the commit and the tag together.
- A Release workflow (GitHub Actions) runs on every `v*` tag. It runs the tests, builds the universal Release app, checks that the app's version matches the tag, packages `Weiki.dmg` and `Weiki.zip`, and publishes a GitHub Release with both.
- A Build workflow builds and tests every push and pull request to `main`.
- `make dmg`, `make zip`, and `make release` package a build locally, the same way CI does.
- `scripts/install.sh` is a one-line installer (`curl … | bash`). It downloads the latest release, replaces `/Applications/Weiki.app`, and launches it. The ZIP also carries `install.command` for anyone who downloads it by hand.
- The README gets an Install section.

Not in this change:
- An in-app updater, and the signed-release flow the other app uses for its updater (draft releases, an update-signing key, a separate publish step). To update, run the installer again.
- Developer ID signing and notarization. Releases are ad-hoc signed, like local builds. The one-liner's download never gets the quarantine flag, and `install.command` clears it.

## Capabilities

### New Capabilities

None. Releases are tooling and documentation, and the app's behavior doesn't change, so this change has no spec deltas (`skip_specs: true`).

### Modified Capabilities

None.

## Impact

- **Files:** `Makefile`, `.github/workflows/build.yml` and `release.yml`, `scripts/install.sh`, `scripts/install.command`, and `README.md`.
- **GitHub:** a release is public as soon as its workflow finishes. The workflows use the repository's own `GITHUB_TOKEN` and need no secrets.
- **Users:** installing quits a running Weiki, which ends its session and releases its hold.
