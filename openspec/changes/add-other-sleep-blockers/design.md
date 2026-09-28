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
`SleepBlockers.list(from:appName:excluding:)` takes each process's `ProcessAssertions` (the name the system recorded, plus what its assertions keep awake), a function that gives an app's Dock name, and Weiki's process ID. It returns `[SleepBlocker]` (name, `keepsDisplayOn`):
- **Naming:** a process goes by its app's name when it has one, and otherwise by its recorded process name.
- **Ignored:** Weiki's own process, `powerd` (the power manager, whose assertions are the system's bookkeeping), and processes whose assertions keep nothing awake.
- **Grouping:** processes are grouped by name, and display wins over system. The list is sorted with `localizedStandardCompare`.

Tests feed it literal values.

### 3. Reading, and what each type means
`SystemPowerAssertions.assertionsByProcess()` wraps `IOPMCopyAssertionsByProcess`. It keeps each process's assertions that are on (`AssertLevel` equals `kIOPMAssertionLevelOn`), turns each type into an `AssertionEffect` (`effect(ofType:)`), and drops processes with none left. `PowerAssertions.swift` stays the only code that imports `IOKit.pwr_mgt`, so the IOKit type names stay there:
- **Display:** `PreventUserIdleDisplaySleep`, and its old name `NoDisplaySleepAssertion`.
- **System:** `PreventUserIdleSystemSleep`, `NoIdleSleepAssertion`, `PreventSystemSleep`, and `NetworkClientActive` (which `IOPMLib.h` says "keeps the system awake while OS X serves active network clients").
- **Everything else** (`Internal*`, `UserIsActive`, `BackgroundTask`, and so on) has no effect.

The process name comes from the assertion's `"Process Name"` key. `IOPMLib.h` doesn't declare that key, but every assertion carries it, and it's what `pmset -g assertions` prints. `proc_name` was tried first, but it returns nothing for root-owned processes such as `powerd` or `coreaudiod`.

A serialized integration test creates a hold and finds it under its own process, with the right effect and the process's name.

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

- *Answered (task 1.1):* a counter bumped on `NSMenu.didBeginTrackingNotification` showed in the status line of the menu that was opening, on each opening (read through System Events three times as #1, #2, #3, and seen in a screenshot 0.35 s after opening). Refreshing on open works, so the timer fallback isn't needed.
- Whether to add each process's reason (the assertion's name, such as "Video Wake Lock") as a second line, if the menu can show it.
