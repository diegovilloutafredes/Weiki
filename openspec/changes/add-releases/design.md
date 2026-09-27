# Design

## Context

See `proposal.md`. Weiki already has a clean universal Release build (`make build` into `build/Release/`), ad-hoc signed through `SIGNING_FLAGS`, and `project.yml` holds `MARKETING_VERSION` ("0.1.0"). The GitHub repository is public, Actions are enabled, the default workflow token is read-only, and no secrets are set. The author's other menu bar app already releases from tags. Its release flow also signs each zip for its in-app updater, and Weiki leaves that part out.

## Goals / Non-Goals

**Goals:**
- One local command cuts a release, and CI builds and publishes it without any secrets.
- Anyone can install the latest release with one command, with no Gatekeeper prompt.
- What CI ships matches what a local `make release` produces.

**Non-Goals:**
- Automatic updates or update notifications.
- Release notes beyond the ones GitHub generates.

## Decisions

### 1. CI publishes the release directly
The Release workflow creates the GitHub Release as its last step, so a failed run publishes nothing. The other app creates a draft and publishes it only after signing the zip locally, because its updater has to verify each release. Weiki has no updater, so a draft step would add a manual step and protect nothing.

### 2. Toolchain: the `macos-26` runner with Xcode 26.5
Both workflows select `/Applications/Xcode_26.5.app` through one `XCODE_PATH` variable, the same toolchain the other app releases with. Weiki needs Xcode 26 or later (`SWIFT_DEFAULT_ACTOR_ISOLATION`), which is what the README claims, so CI on 26.5 also checks that claim.
- *Alternative:* the `xcode-27` image, which matches the local Xcode 27.0 build exactly. It is a public preview, so its label may change and it has no SLA. It's the fallback if 26.5 can't build Weiki.

### 3. Releases are ad-hoc signed
CI builds with the Makefile's default `CODE_SIGN_IDENTITY="-"`, as local builds do. The other app's CI uses `CODE_SIGNING_ALLOWED=NO` instead.
- Ad-hoc signing seals the whole bundle, so `codesign --verify --deep --strict` passes on a released app.
- Launch at Login was verified on an ad-hoc-signed bundle.
- It needs no certificate.
- Developer ID signing and notarization can be added as conditional steps once there is a certificate, as in the other app.

### 4. Packaging reuses the build
- `make dmg` packages `build/Release/Weiki.app` into `build/Weiki.dmg`, with a link to `/Applications`, using `hdiutil`.
- `make zip` packages it into `build/Weiki.zip`, with `install.command` beside the app at the archive root.
- `make release` runs `build`, `dmg`, and `zip`. CI runs `make release`, so a local run produces the same files.
- The file names carry no version, so `releases/latest/download/Weiki.zip` stays a stable URL.
- Everything lands under `build/`, which git already ignores and `make clean` already removes.

### 5. `make tag VERSION=x.y.z`
1. Checks, which fail within a second: the version has the form `x.y.z`, the branch is `main`, the working tree is clean, and the tag doesn't already exist.
2. Runs `make test`.
3. Writes the version into `project.yml` and commits "Bump version to x.y.z". The commit is skipped if `project.yml` already has that version, so the first release can ship the current 0.1.0.
4. Creates the annotated tag `vx.y.z`.
5. Runs `git push --atomic origin main vx.y.z`, so the commit and the tag reach GitHub together or not at all.

It differs from the other app's `tag` target in these ways:
- The checks run before the tests.
- The branch check: without it, a bump committed on another branch would be tagged, but `git push origin main` wouldn't push it.
- The push is atomic.
- There's no lint step, because Weiki has no linter.

### 6. The Release workflow checks the version
After the build, the workflow compares the app's `CFBundleShortVersionString` with the tag, without its `v`. This means a tag pushed without `make tag` can't publish a build that reports a different version. The workflow also runs the tests itself, because the tag's Release run and the `main` push's Build run start at the same time. The other app does the same.

### 7. Installers
`scripts/install.sh` (the one-liner) and `scripts/install.command` (inside the zip) both:
1. Quit a running Weiki and wait for it to exit, using the same wait loop as `make run`.
2. Delete the old app before copying, because Launch Services caches an app that is replaced in place.
3. Copy the new app into `/Applications`.
4. Open the app.

`install.command` also clears the quarantine flag, which a browser download carries. The one-liner doesn't need to: `curl` doesn't set the flag, so it never triggers Gatekeeper. The README links to the script at `main/scripts/install.sh`, so that path must not change.

### 8. Permissions
Only the release job gets `contents: write`, which it needs to create the release. The Build workflow keeps the read-only default.

## Risks / Trade-offs

- **Launch at Login after an update.** Every build has a new ad-hoc signature, so macOS might not carry the login item over when the app is replaced. → A manual task installs a second build over the first and checks that the ✓ survives. If it doesn't, the README tells people to turn the item on again after updating.
- **Weiki has only been built with Xcode 27.** → The first Build run shows whether Xcode 26.5 builds it. If not, both workflows move to the `xcode-27` image and the README's requirement changes to match.
- **Real power assertions on CI.** `SystemPowerAssertionsTests` create IOKit assertions on the runner and read them back. → The first Build run shows whether hosted runners allow that. If they don't, the tests are not skipped quietly; the fix is a deliberate decision.
- **Gatekeeper blocks browser downloads.** Ad-hoc signed copies downloaded in a browser are quarantined. → The one-liner avoids the flag, `install.command` clears it, and the README explains "Open Anyway".
- **`make tag` fails to push.** For example, `main` is behind `origin/main`. → The atomic push leaves GitHub untouched. Delete the local tag, drop the bump commit, and tag again.
- **The Release workflow fails after the tag is pushed.** Publishing is the last step, so no release appears. → Fix the cause, delete the tag on GitHub and locally, and tag again.

## Migration Plan

Nothing to migrate. To withdraw a release, run `gh release delete vx.y.z --cleanup-tag` and delete the local tag.

## Open Questions

- The first release's version: 0.1.0 as it is, or a bump. It's chosen when the first release is cut and doesn't affect this design.
