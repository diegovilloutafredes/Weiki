PROJECT   = Weiki.xcodeproj
SCHEME    = Weiki
APP       = Weiki.app
BUILD_DIR = build/Release
ARCH     := $(shell uname -m)

# CI override: make build SIGNING_FLAGS="CODE_SIGNING_ALLOWED=NO"
SIGNING_FLAGS ?= CODE_SIGN_IDENTITY="-"

.PHONY: generate build run test clean

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

test: generate
	@echo "==> Running tests..."
	xcodebuild test \
	           -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -destination 'platform=macOS,arch=$(ARCH)' \
	           $(SIGNING_FLAGS)

# ── Local dev ────────────────────────────────────────────────────────────────
# Quits a running copy before replacing it; quitting also releases any
# keep-awake hold that copy had.

run: build
	@echo "==> Installing and launching..."
	@pkill -x Weiki 2>/dev/null || true
	@# Wait (up to 5 s) for it to exit, so `open` can't hand off to the dying instance.
	@for i in $$(seq 50); do pgrep -x Weiki >/dev/null || break; sleep 0.1; done
	@rm -rf /Applications/$(APP)
	@cp -R $(BUILD_DIR)/$(APP) /Applications/$(APP)
	@open /Applications/$(APP)

# ── Cleanup ──────────────────────────────────────────────────────────────────

clean:
	@echo "==> Cleaning..."
	@pkill -x Weiki 2>/dev/null || true
	@rm -rf build
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Weiki-*
