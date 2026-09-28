PROJECT   = Weiki.xcodeproj
SCHEME    = Weiki
APP       = Weiki.app
BUILD_DIR = build/Release
DIST_DIR  = build/dist
DMG       = build/Weiki.dmg
ZIP       = build/Weiki.zip
ARCH     := $(shell uname -m)
# bash for `set -o pipefail` in `test`; /bin/sh can be another shell.
SHELL    := /bin/bash

# Ad-hoc signing, locally and on CI (releases ship it too).
# To build unsigned: make build SIGNING_FLAGS="CODE_SIGNING_ALLOWED=NO"
SIGNING_FLAGS ?= CODE_SIGN_IDENTITY="-"

.PHONY: generate build run test clean icon release dmg zip tag

# ── Generate Xcode project (XcodeGen) ─────────────────────────────────────────
# project.yml is the source of truth; Weiki.xcodeproj is generated and
# git-ignored. build/test depend on this so the project is always in sync.

generate:
	@command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen not found — brew install xcodegen"; exit 1; }
	@echo "==> Generating $(PROJECT) from project.yml..."
	@xcodegen generate --quiet

# ── Build ─────────────────────────────────────────────────────────────────────

build: generate
	@echo "==> Building..."
	@rm -rf $(BUILD_DIR) && mkdir -p $(BUILD_DIR)
	@xattr -w com.apple.xcode.CreatedByBuildSystem true "$(CURDIR)/$(BUILD_DIR)"
	xcodebuild -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination 'generic/platform=macOS' \
	           -configuration Release \
	           -quiet \
	           clean build \
	           CONFIGURATION_BUILD_DIR="$(CURDIR)/$(BUILD_DIR)" \
	           $(SIGNING_FLAGS)

# ── Test ─────────────────────────────────────────────────────────────────────
# When a test crashes the test host, xcodebuild relaunches it and skips that
# test, and it can still report success, so a relaunch in the log fails the run.

test: generate
	@echo "==> Running tests..."
	@mkdir -p build
	set -o pipefail; xcodebuild test \
	           -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination 'platform=macOS,arch=$(ARCH)' \
	           $(SIGNING_FLAGS) 2>&1 | tee build/test.log
	@if grep -q "Restarting after unexpected exit" build/test.log; then \
	  echo "error: the test host was relaunched after a crash or a timeout (see build/test.log)"; exit 1; \
	fi

# ── Packaging ────────────────────────────────────────────────────────────────
# The files a GitHub release carries; the Release workflow runs `make release`.
# The names have no version, so releases/latest/download/Weiki.zip always
# serves the newest one. dmg and zip package the existing build/Release.

release: build dmg zip

dmg:
	@echo "==> Creating DMG..."
	@rm -f $(DMG)
	@TMP=$$(mktemp -d) && \
	  cp -R $(BUILD_DIR)/$(APP) "$$TMP/$(APP)" && \
	  ln -s /Applications "$$TMP/Applications" && \
	  hdiutil create -volname "Weiki" -srcfolder "$$TMP" \
	    -ov -format UDZO "$(DMG)" -quiet && \
	  rm -rf "$$TMP"
	@echo "  -> $(DMG)"

zip:
	@echo "==> Creating ZIP..."
	@rm -rf $(DIST_DIR) && mkdir -p $(DIST_DIR)
	@cp -R $(BUILD_DIR)/$(APP) $(DIST_DIR)/$(APP)
	@cp scripts/install.command $(DIST_DIR)/install.command
	@chmod +x $(DIST_DIR)/install.command
	@rm -f $(ZIP)
	@cd $(DIST_DIR) && zip -rqy "$(CURDIR)/$(ZIP)" .
	@echo "  -> $(ZIP)"

# ── Release tagging ──────────────────────────────────────────────────────────
# make tag VERSION=1.2.0 sets MARKETING_VERSION, commits it, tags v1.2.0, and
# pushes both; the Release workflow then builds and publishes the release.
# The checks run first, so a mistake fails before the tests do.

tag:
	@if ! echo "$(VERSION)" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$'; then echo "Usage: make tag VERSION=x.y.z"; exit 1; fi
	@if [ "$$(git branch --show-current)" != main ]; then echo "Releases are tagged on main"; exit 1; fi
	@if [ -n "$$(git status --porcelain)" ]; then echo "Working directory is not clean — commit changes first"; exit 1; fi
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then echo "Tag v$(VERSION) already exists"; exit 1; fi
	@$(MAKE) test
	@sed -i '' 's/MARKETING_VERSION: .*/MARKETING_VERSION: "$(VERSION)"/' project.yml
	@# No bump commit when project.yml already has this version.
	@git diff --quiet project.yml || { git add project.yml && git commit -q -m "Bump version to $(VERSION)"; }
	git tag -a "v$(VERSION)" -m "v$(VERSION)"
	@# Atomic: the commit and the tag reach GitHub together or not at all.
	git push --atomic origin main "v$(VERSION)"
	@echo "==> Pushed v$(VERSION). The Release workflow builds and publishes it."

# ── Local dev ────────────────────────────────────────────────────────────────
# Quits a running copy before replacing it; quitting also releases any
# keep-awake hold that copy had.

run: build
	@echo "==> Installing and launching..."
	@pkill -x Weiki 2>/dev/null || true
	@# Wait (up to 5 s) for it to exit and for Launch Services to let it go: until
	@# then, `open` fails with error -600.
	@for i in $$(seq 50); do pgrep -xq Weiki || [ -n "$$(lsappinfo find bundleid=com.weiki.app)" ] || break; sleep 0.1; done
	@rm -rf /Applications/$(APP)
	@cp -R $(BUILD_DIR)/$(APP) /Applications/$(APP)
	@open /Applications/$(APP)

# ── App icon ─────────────────────────────────────────────────────────────────
# Redraws every size in Weiki/Assets.xcassets/AppIcon.appiconset. `xcrun` picks
# Xcode's toolchain; a swiftly `swift` on PATH fails against the Xcode SDK.

icon:
	@xcrun swift scripts/generate-appicon.swift

# ── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	@echo "==> Cleaning..."
	@pkill -x Weiki 2>/dev/null || true
	@rm -rf build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Weiki-*
