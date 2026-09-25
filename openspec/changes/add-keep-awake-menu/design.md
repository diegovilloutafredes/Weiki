# Design

## Context

This is a new repository; `proposal.md` explains why it exists. The author's other menu bar app supplies the build pattern: XcodeGen and a Makefile, `MenuBarExtra`, and no Dock icon. It also supplies one constraint that matters here: a `MenuBarExtra` label cannot reliably show an image and text together.

Facts established before writing this design (macOS 27, Xcode 27):

- **Probe against the real power-management API,** reading holds back with `IOPMCopyAssertionsByProcess`:
  - A new hold is visible within 1–3 ms, and a released hold disappears within about 1 ms.
  - A hold created with a 2-second timeout and `kIOPMAssertionTimeoutActionRelease` disappeared at 2.02 s.
  - Releasing a hold after its timeout has fired returns `kIOReturnBadArgument` (`0xe00002c2`) and has no other effect.
  - Creating the new hold before releasing the old one leaves exactly one hold with no observable gap. Hold IDs increase with each creation, so an old ID is never reused.
- **`IOPMLib.h`** (Xcode 27 SDK):
  - `IOPMAssertionCreateWithDescription` is documented as "the preferred API to create a power assertion".
  - A timeout given without a timeout action defaults to `TurnOff`, not `Release`.
  - `PreventUserIdleDisplaySleep` also blocks idle system sleep: "While the display is prevented from dimming, the system cannot go into idle sleep."
  - Neither assertion type prevents sleep from closing the lid, the Apple menu, or a low battery.
- **Xcode 27 `Swift.xcspec`:**
  - `SWIFT_DEFAULT_ACTOR_ISOLATION` accepts `nonisolated` or `MainActor`.
  - `SWIFT_APPROACHABLE_CONCURRENCY` only applies in the Swift 4 and 5 language modes.
- **`Task.sleep`** uses the continuous clock by default. The design does not rely on that (see Decision 5).

## Goals / Non-Goals

**Goals:**
- The icon never shows the Mac as held awake when it is not, and never shows it as off while a hold exists.
- Every hold ends when it should: when the user turns it off, when its time runs out, or when Weiki quits. A system-enforced timeout releases a timed hold even if Weiki hangs.
- The only code that calls the power-management API is small and covered by an integration test against the real system. Everything else is testable without touching the system.

**Non-Goals:**
- Resuming a session after relaunch.
- Countdown text anywhere: in the menu bar or inside the menu.
- A test seam for SwiftUI views. The menu and window are verified by running the app and checking `pmset -g assertions`.

## Decisions

### 1. Power assertions directly, not the `caffeinate` binary
Weiki calls `IOPMAssertionCreateWithDescription` and `IOPMAssertionRelease` itself.

- **Alternative:** run `/usr/bin/caffeinate` as a child `Process`, passing `-w <own pid>` so it exits with Weiki. It was verified that `-t` and `-w` work together. Rejected for three reasons:
  - It adds a process to supervise.
  - The remaining time can't be queried from it.
  - Its holds would be listed as "caffeinate command-line tool" instead of Weiki.

### 2. Hold parameters
- **Type:** `kIOPMAssertPreventUserIdleDisplaySleep` when Keep Display On is enabled; `kIOPMAssertPreventUserIdleSystemSleep` when it is disabled.
- **Name:** `"Weiki"`.
- **Details:** mode plus end, for example `"Display kept on, until 14:35"` or `"Display allowed to sleep, indefinitely"`.
- **Timeout:** the session's remaining seconds, or `0` for an indefinite session.
- **Timeout action:** `kIOPMAssertionTimeoutActionRelease`, always passed explicitly, because the default is `TurnOff`.
- **Human-readable reason and localization bundle path:** `nil` in v1. A reason string requires a localization bundle, and the name and details already identify the hold in `pmset` and Activity Monitor.

### 3. A narrow seam around the system calls
A protocol, `PowerAssertionService`, has two methods:
- `acquire(keepsDisplayOn:timeout:details:) throws -> UInt32`, which returns the hold ID.
- `release(_:)`.

`SystemPowerAssertions` is its only production implementation, and the only file that imports IOKit. The session controller receives the service through its initializer; tests pass a fake that records every call in order.

- **Alternative:** no protocol, testing the controller against the real API. This is workable, since the probe shows holds are observable within milliseconds. Rejected because:
  - The refused-hold path can't be triggered against the real API.
  - The acquire-before-release order can't be observed.
  - Controller tests would depend on system state.

  The real implementation still gets its own integration suite (Decision 11).

### 4. Replacing a hold: acquire the new one, then release the old one
Restarting a session and changing the mode during a session both replace the hold. The new hold is always acquired first and the old one released after, which the probe showed leaves no gap. If acquiring the replacement throws, the controller releases the old hold and turns off, which keeps the first goal.

- **Alternative:** release first, then acquire. Rejected because it leaves a moment when nothing holds the Mac awake.

### 5. Session state and who ends a session
`AwakeController` is `@Observable` and runs on the main actor (the module default). Its state is `.off` or `.on(endDate: Date?)`, where `nil` means indefinite, plus the current hold ID.

- **The absolute `endDate` is the source of truth.** One task loop sleeps for `min(remaining, 60 s)` and then re-reads the wall clock. At or past the end time, it releases the hold and turns off.
- **The 60-second cap removes a dependency on the timer's clock.** Whether or not the timer counts time the Mac spends asleep, a Mac that wakes after the end time turns off within 60 seconds.
- **The system timeout from Decision 2 is only a safety net** for a hung app. It and the loop can both fire at the end time. Release is therefore best-effort and its result is ignored, and the state turns off regardless. The probe showed that releasing an expired hold only returns an error.
- **Holds are released explicitly, never in `deinit`.** Deinitializers are nonisolated, and quitting releases everything anyway because the process exits.
- **Alternative:** a timer set to the end time, plus an `NSWorkspace.didWakeNotification` observer that re-checks. It gives the same result with one more moving part.
- **Alternative:** rely only on the system timeout and poll the system for state. Rejected because it ties the UI to polling the system.

### 6. Persistence
Only one value is persisted: `keepsDisplayOn`, stored in `UserDefaults` under that key and defaulting to `true`. The controller takes a `UserDefaults` instance in its initializer, and tests pass a throwaway suite. Sessions are never persisted, so every launch starts off.

### 7. Menu bar UI
A SwiftUI `MenuBarExtra` with `.menuBarExtraStyle(.menu)` and an icon-only label: `Image(systemName: "cup.and.saucer")` when off and `"cup.and.saucer.fill"` when on. The image is a template, so it follows the menu bar's appearance. Showing only the icon avoids the composed-image workaround needed for text in the label.

- **The status line is computed when the menu opens.** The `.menu` style is backed by `NSMenu`, which does not re-render while open, so the status line shows the end time rather than a countdown. This is a constraint: no live countdown in the menu.
- **Menu contents:** a disabled `Text` for the status line, `Button`s, a `Section("Keep Awake For")`, a `Toggle` (which renders as a checkmark item), and `Divider`s.
- **Alternatives rejected during brainstorming:**
  - The `.window` popover style used by the author's other menu bar app: it stays open until clicked away and needs more layout code.
  - An AppKit `NSStatusItem` with left-click to toggle: `MenuBarExtra` can't act on a click, so this would mean dropping `MenuBarExtra`.

### 8. Custom duration window
A SwiftUI `Window("Custom Duration", id: "custom-duration")` scene with `.windowResizability(.contentSize)` and `.defaultLaunchBehavior(.suppressed)`, so it never opens at launch.

- "Custom…" calls `openWindow(id:)` and then `NSApp.activate()`. That is the macOS 14+ API; `activate(ignoringOtherApps:)` is deprecated.
- Start calls the controller and then `dismissWindow(id:)`.
- `.defaultLaunchBehavior` requires macOS 15, which sets the deployment target to macOS 15.0.
- **Alternatives:** an `NSAlert` with an accessory view, which works on macOS 14 but is an AppKit modal; or a submenu with more presets, which doesn't allow a custom duration.

### 9. Status line text
A pure function takes the state, `now`, a calendar, and a locale, and returns the status string. It is unit-tested with fixed inputs. It uses `Date.FormatStyle`, so the time follows the system format, and it adds the abbreviated weekday when the end time is not on the same calendar day as `now`.

The user-visible strings are ready for translation, so adding Spanish later only means adding a String Catalog. The status strings use `String(localized:)`, for example `String(localized: "Awake until \(time)")`, and every other label is a SwiftUI string literal, which is already a localization key. The hold's details text (Decision 2) is meant for `pmset` and stays in English.

### 10. Project setup
- **XcodeGen:** `project.yml` is the source of truth, and the generated `Weiki.xcodeproj` is git-ignored. There are two targets: the `Weiki` application and `WeikiTests`, a unit-test bundle hosted by the app.
- **Swift settings:** at project level, `SWIFT_VERSION: 6.0` and `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor`. `SWIFT_APPROACHABLE_CONCURRENCY` is not set, because it only applies in Swift 4 and 5 mode.
  - **Alternative:** the other app's Swift 5 with `SWIFT_STRICT_CONCURRENCY: complete`. Rejected for a new codebase.
- **Target settings:**
  - Deployment target: `MACOSX_DEPLOYMENT_TARGET: 15.0`.
  - Info.plist: `GENERATE_INFOPLIST_FILE: YES` with `INFOPLIST_KEY_LSUIElement: YES`, so there is no Info.plist file.
  - Bundle ID: `com.weiki.app`. This is an assumption that follows the pattern of the author's other menu bar app.
  - Ad-hoc signing (`CODE_SIGN_IDENTITY: "-"`), no entitlements, no sandbox. Hardened runtime waits for the release pipeline.
- **Makefile,** modeled on the author's other menu bar app:
  - `generate`
  - `build`: a clean Release build.
  - `run`: quit any running copy, build, copy to `/Applications`, and launch.
  - `test`
  - `clean`

### 11. Tests
- **Framework:** Swift Testing.
- **Test host:** `TEST_HOST` is the app itself. Launching the app has no side effects (it starts off and reads one defaults key), so unlike the author's other menu bar app it needs no "running unit tests" guard.
- **Integration suite for `SystemPowerAssertions`:** `@Suite(.serialized)`, which applies to everything inside it. It reads the test process's holds back through `IOPMCopyAssertionsByProcess` and checks `AssertType`, `AssertName`, `Details`, `TimeoutSeconds`, and `TimeoutAction`, and that each hold is gone after release. Each test releases what it creates.
- **Controller tests:** use the recording fake and a throwaway `UserDefaults` suite. Tests of timed endings use durations under a second.
- **End-to-end checks:** run against the built app and `pmset -g assertions`. They are scripted through System Events (`osascript`) when Accessibility access is available, and done by hand otherwise.

## Risks / Trade-offs

- **The Custom window opens behind other apps,** because activation is cooperative for an app with no Dock icon. → Call `NSApp.activate()` after `openWindow`. If that proves insufficient, call `orderFrontRegardless()` on the window (see Open Questions).
- **The app timer and the system timeout race at the end time.** → Release is best-effort and its result is ignored; the state turns off regardless.
- **A session can end up to 60 seconds late after waking past its end time.** → Acceptable. The system timeout may already have released the hold, and the spec states "within one minute of waking".
- **The status line goes stale while the menu stays open.** → It shows the end time, which stays correct, rather than a countdown.
- **Integration tests hold real assertions during `make test`.** → The suite is serialized, each test releases what it creates, and every hold ends when the test process exits.
- **Closing the lid, the Apple menu, and a low battery still put the Mac to sleep.** → Documented as a non-goal in `proposal.md`.
- **`com.weiki.app` is not a domain the owner controls.** → Fine for local use; revisit with the release pipeline.

## Migration Plan

This is a new app, so there is nothing to migrate. `make run` installs it by copying `Weiki.app` to `/Applications`. To roll back, quit Weiki and delete `Weiki.app`. The only thing left behind is the `keepsDisplayOn` default in the `com.weiki.app` domain.

## Open Questions

- Does `NSApp.activate()` alone reliably bring the Custom window to the front when it is opened from the menu, or is `orderFrontRegardless()` also needed? This will be answered while implementing the window (task group 6). The answer does not change the specs, the approach, or the task breakdown.
