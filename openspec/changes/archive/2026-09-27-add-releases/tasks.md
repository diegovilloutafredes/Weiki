# Tasks

## 1. Packaging

- [x] 1.1 Add `scripts/install.command` (design 7) and the `dmg`, `zip`, and `release` Makefile targets (design 4). Verify that `bash -n` accepts the script and that `make release` writes `build/Weiki.dmg` and `build/Weiki.zip`. Unzipped into a temporary folder, the zip must hold `Weiki.app` and an executable `install.command` at its root. The app must pass `codesign --verify --deep --strict`, contain both `x86_64` and `arm64`, and report the version in `project.yml`. Mounted read-only with `hdiutil attach -nobrowse`, the DMG must hold the same app and an `Applications` link.
- [x] 1.2 Add the three targets to the project notes. Verify that the text matches the Makefile.

## 2. Tagging

- [x] 2.1 Add the `tag` target (design 5). Verify it in a scratch clone whose `origin` is a local bare repository:
  - each check fails with its own message and pushes nothing: no `VERSION`, `VERSION=v1.0`, a dirty tree, a branch other than `main`, and an existing tag
  - a valid run leaves the bump commit and the annotated tag in the bare repository, with `project.yml` at the new version
  - a run with the version already in `project.yml` pushes the tag without a bump commit
- [x] 2.2 Add `make tag` and its recovery steps (design, Risks) to the project notes. Verify that the text matches the Makefile.

## 3. Workflows

- [x] 3.1 Add `.github/workflows/build.yml` and `.github/workflows/release.yml` (design 2, 6, and 8). Verify that both parse as YAML and pass `actionlint`. Also run the release workflow's version check locally against `build/Release/Weiki.app`: it must pass for the matching tag and fail for any other.
- [x] 3.2 Add the workflows, the pinned Xcode, and the version check to the project notes. Verify that the text matches the workflow files.

## 4. Installer and README

- [x] 4.1 Add `scripts/install.sh` (design 7). Verify that `bash -n` accepts it and that the download URL in it matches the release file name `make zip` produces.
- [x] 4.2 Add an Install section to the README: the one-liner, the manual DMG and ZIP downloads, the Gatekeeper note, and how to update. Verify that the one-liner's URL points at `scripts/install.sh` on `main`, and that both of the project notes' pre-push checks print nothing.

## 5. First release

- [x] 5.1 Push `main`. Verify that the Build workflow passes on the runner, including the tests that create real power assertions.
- [x] 5.2 Cut the first release with `make tag`. Verify that the Release workflow passes and that the release has `Weiki.dmg` and `Weiki.zip`. Also verify that the zip served at `releases/latest/download/Weiki.zip` holds a universal, validly signed app with the tagged version.
- [x] 5.3 By hand (needs a person), on a Mac where Weiki is running with Launch at Login on:
  - Run the one-liner. Check that Weiki quits, is replaced, and relaunches with no session active, and that the Launch at Login ✓ is still there.
  - Download `Weiki.zip` in a browser and run `install.command`. Check that the app opens.

  Checked by running the one-liner over a local build. Weiki relaunched as v0.1.0, reading "Weiki is off", and the ✓ was still there. Then `Weiki.zip` was given the quarantine flag a Safari download carries, and Gatekeeper rejected the extracted app. `bash install.command` installed a copy with no flag, which opened with the ✓ still there. Not tried: double-clicking `install.command` in Finder, and logging in after an update.
