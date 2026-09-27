# Design

## Context

See `proposal.md`. Two facts shape the design.

**The `.menu`-style menu doesn't rebuild when it opens.** SwiftUI rebuilds it only when observed state changes. The layer-1 design verified this, including that a `TimelineView` in it never updates.

**IOKit gives the data but no change notification.**
- `IOPMCopyAssertionsByProcess` returns every process's active assertions: a dictionary from process ID to an array of dictionaries with `AssertType`, `AssertName`, and `AssertLevel`. Any process can call it, and `SystemPowerAssertionsTests` already does.
- `IOPMLib.h` declares no public notification for assertions changing.

Live `pmset -g assertions` output shows the bookkeeping that is always present:
- `powerd` holding "Powerd - Prevent sleep while display is on" (`PreventUserIdleSystemSleep`) whenever the display is on, and `InternalPreventDisplaySleep`
- `WindowServer` holding `UserIsActive`

It also shows real blockers: `caffeinate`, `xcodebuild` ("Xcode running tests.").

## Goals / Non-Goals

**Goals:**
- An accurate list the moment the menu opens, without polling while the menu is closed.
- A pure, tested rule for what counts, fed by a thin reader of the system's assertions.

**Non-Goals:**
- Acting on the list, such as quitting a process or bringing an app forward.
- Explaining each assertion's own reason text.

## Decisions

### 1. Refresh when the menu opens
The model refreshes on `NSMenu.didBeginTrackingNotification`, which AppKit posts when any of the app's menus starts tracking. Weiki's only menu is its status item's menu, so a text field's context menu in the Custom window just adds a harmless extra refresh. The first task checks that the menu that is opening shows the refreshed list.
- *Fallback, if it doesn't:* refresh every 15 seconds on a tolerant timer, and whenever Weiki's own session changes.
- *Rejected:* the private `com.apple.system.powermanagement.assertions` notification, because it isn't API.

### 2. What counts, as a pure function
`SleepBlockers.list(from:name:excluding:)` takes the assertions by process ID, a function that names a process, and Weiki's process ID. It returns `[SleepBlocker]` (name, `keepsDisplayOn`):
- **Display types:** `PreventUserIdleDisplaySleep`, and its old name `NoDisplaySleepAssertion`.
- **System types:** `PreventUserIdleSystemSleep`, `NoIdleSleepAssertion`, `PreventSystemSleep`, and `NetworkClientActive` (which `IOPMLib.h` says "keeps the system awake while OS X serves active network clients").
- **Ignored:** every other type (`Internal*`, `UserIsActive`, `BackgroundTask`, and so on), assertions whose level isn't on, Weiki's own process, and the process named `powerd`. `powerd` is the power manager itself, so its assertions are the system's bookkeeping.
- **Grouping:** processes are grouped by name, and display wins over system. The list is sorted with `localizedStandardCompare`.

Tests feed it literal dictionaries.

### 3. Reading and naming
`SystemPowerAssertions.processAssertions()` wraps `IOPMCopyAssertionsByProcess` and returns `[pid_t: [ProcessAssertion]]` (type, name, whether it's on). It lives in `PowerAssertions.swift`, which stays the only code that imports `IOKit.pwr_mgt`. A serialized integration test creates a hold and finds it under its own process with the right type.

A process's name is its app's `localizedName` when it has one (the Dock name), and otherwise `proc_name`.

### 4. Model and menu
`SleepBlockers` is `@Observable`. `WeikiApp` owns it and passes it to `MenuContent`, which shows:

```swift
Section("Also Keeping the Mac Awake") { Text("\(name) — keeps the display on") }
```

`Text` items in a menu are disabled, so choosing one does nothing. The section is omitted when the list is empty. The interpolated literal is a localizable key.

## Risks / Trade-offs

- **The menu might not show a change made while it opens.** → Task 1 checks it first. The fallback is the timer.
- **Excluding `powerd` by name.** It's the only process whose assertions are always bookkeeping. If macOS renames it, its "while display is on" hold would show up, which is noticeable and harmless.
- **Some processes have technical names,** such as `coreaudiod` while audio plays. → They're shown as they are, which is still better than `pmset`.

## Open Questions

- Whether to add each process's reason (the assertion's name, such as "Video Wake Lock") as a second line, if the menu can show it.
