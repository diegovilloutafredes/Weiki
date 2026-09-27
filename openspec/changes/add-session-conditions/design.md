# Design

## Context

See `proposal.md`. Today `AwakeController` has two states, `.off` and `.on(until: Date?)`, along with `activeOption` for the menu's checkmark, `minutesLeft` for the menu bar, one hold, and an end loop. Each system API sits behind a small protocol with a fake in the tests: `PowerAssertionService` (IOKit), and `LoginItemService` (ServiceManagement). The menu uses the `.menu` style, which SwiftUI turns into an `NSMenu` that is rebuilt only when observed state changes.

Facts established before writing this design:

- **`IOPMLib.h` and `IOPowerSources.h`** (macOS 27 SDK):
  - IOKit has no hold that applies only on AC power. `kIOPMAssertionTypePreventSystemSleep` is "not supported in any OS X releases" since 10.9, so Weiki has to watch the power source itself.
  - `IOPSGetProvidingPowerSourceType(IOPSCopyPowerSourcesInfo())` returns "AC Power", "Battery Power", or "UPS Power".
  - `kIOPSNotifyPowerSource` (`notify(3)`) is posted only when the active source changes, not when the battery level changes.
- **AppKit:**
  - `NSRunningApplication.isTerminated` supports key-value observing.
  - `NSWorkspace.didLaunchApplicationNotification` and `didTerminateApplicationNotification` are posted on `NSWorkspace.shared.notificationCenter`, and never for background or `LSUIElement` apps.
  - `runningApplications` lists `NSRunningApplication`s with an `activationPolicy`; `.regular` means the app appears in the Dock.
- **UserNotifications:**
  - The first `requestAuthorization(options:)` call shows the prompt, and later calls return the stored answer.
  - A request with a `nil` trigger is delivered immediately.
  - A notification that arrives while the app is active is shown only if the delegate's `willPresent` asks for it.
  - The author's other menu bar app found that the delegate has to be its own `NSObject` subclass: a `@MainActor` class as the delegate fails to compile under Swift 6 concurrency.

## Goals / Non-Goals

**Goals:**
- The existing invariants still hold. A new hold is acquired before the old one is released, the end date decides when a session ends, and Weiki never shows a hold that doesn't exist, so a paused session shows as paused.
- Every new system API gets its own seam and a fake. `make test` never shows a permission prompt, and never depends on the real power source or the apps that happen to be running.

**Non-Goals:**
- App icons in the submenu, a battery-level threshold, and notifications for endings other than a timer running out.

## Decisions

### 1. One session value
`AwakeController.State` becomes `.off` or `.on(until: SessionEnd, paused: Bool)`. `SessionEnd` is `.never`, `.date(Date)`, or `.appQuits(WatchedApp)`, and `WatchedApp` holds the app's process ID and name. `DurationOption` gains `.untilQuit(WatchedApp)`, which has no duration.
- *Alternative:* keep `.on(until: Date?)` and add `watchedApp` and `isPaused` properties. Rejected, because the status line and the label would then read three values that have to stay consistent. With one value, `statusLine(now:)` stays one exhaustive, pure `switch`, and a test asserts one value.

### 2. Watching the chosen app
Weiki watches the chosen `NSRunningApplication`'s `isTerminated` through key-value observing. That fires however the app ends, including a crash or a force quit, and it doesn't rely on workspace notifications. The callback moves to the main actor, and it stops the session only if the session still waits for that same process. Because Weiki keeps the `NSRunningApplication` itself rather than just its process ID, a reused ID can't be mistaken for the app. An app that has already terminated when it's chosen starts no session. The seam is `AppQuitWatcher`, with `SystemAppQuitWatcher` for AppKit and a fake for the tests.

### 3. The list of running apps
`RunningApps` (`@Observable`) holds the `.regular` apps from `NSWorkspace.shared.runningApplications`, without Weiki's own process, sorted by name with `localizedStandardCompare`. It refreshes on the workspace's launch and terminate notifications, which are posted for exactly the apps it lists. It has to be observable because the `.menu` content is an `NSMenu` snapshot. The submenu is a SwiftUI `Menu` inside the `MenuBarExtra` content, and the first task checks that it becomes a real submenu that follows the list.

### 4. The power source
`PowerSourceService` has a read (`isOnACPower`) and a change callback. `SystemPowerSource` (its own file, importing `IOKit.ps`) checks `IOPSGetTimeRemainingEstimate() == kIOPSTimeRemainingUnlimited`, the check `IOPowerSources.h` pairs with `kIOPSNotifyPowerSource`, so battery and UPS both count as battery. A test compares it with `IOPSGetProvidingPowerSourceType`. It listens for `kIOPSNotifyPowerSource` with `notify_register_dispatch` on the main queue, and it reads the source again on `NSWorkspace.didWakeNotification` in case it changed during sleep. A Mac without a battery always reports AC power, so the setting simply never pauses there. The item still shows, because hiding it would need a battery check for little gain.

### 5. Pausing lives in `hold(until:)`
`onlyOnACPower` is stored under the UserDefaults key `onlyOnACPower` (default `false`), the same way as `keepsDisplayOn`. `hold` becomes the one place that decides:
- When the setting is on and the Mac is on battery, it releases any hold and sets `.on(until: end, paused: true)`.
- Otherwise it acquires a hold with the remaining time as its timeout, before releasing the old one.

These all call it with the session's current end: a change of power source, the setting's `didSet`, and a mode change. The end loop keeps running while the session is paused, so `minutesLeft` keeps counting and a timed session ends on time. If the hold is refused when the session resumes, `hold` turns the session off, as it already does.

### 6. Notifications
`AwakeController` gets an `onTimerEnd: (Date) -> Void` in `init`, which does nothing by default. The end loop calls it just before `stop()` when a timed session runs out. Turn Off, a replacement, a refused hold, and the app quitting all go through `stop()` directly, so they post nothing. The controller never imports UserNotifications.

`WeikiApp` connects `onTimerEnd` to `EndNotifications`, an `@Observable` model built like `LoginItem`:
- `isEnabled` means the saved choice is on and macOS allows notifications, read at launch and after each choice.
- Choosing the item when notifications were declined opens System Settings at `x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.weiki.app`. If that page doesn't exist on some macOS version, it opens the Notifications page instead.

Its seam, `NotificationService`, has a status read, a permission request, and a post. `SystemNotificationService` uses `UNUserNotificationCenter`, and a separate `NSObject` delegate returns `[.banner, .sound]` from `willPresent`, so the banner also appears while Weiki is the active app. The notification is titled "Weiki is off", and its body gives the end time ("The session ended at 15:00.").

### 7. What the menu bar and menu show
- **Label:** filled means the session holds the Mac awake (on and not paused). The text is "∞", the time left, or the app's name, cut to 10 characters plus "…".
- **Status line:**
  - "Awake until \(app) quits"
  - "Paused on battery"
  - "Paused on battery, until \(time)"
  - "Paused on battery, until \(app) quits"

  All of them use `String(localized:)`.
- **Hold details** for `pmset`: for example "Display kept on, until Xcode quits".
- **Menu order:**
  - the "Keep Awake For" section, ending with "Custom…" and then "Until an App Quits ▸"
  - Keep Display On
  - Only on AC Power
  - Notify When Time's Up
  - Launch at Login
  - a divider, then Quit

## Risks / Trade-offs

- **A SwiftUI `Menu` in a `.menu`-style `MenuBarExtra` may not become a live submenu.** → The first task checks it before anything is built on it. If it fails, the fallback is a flat list of apps under a "Keep Awake Until…" section.
- **Key-value observing callbacks arrive off the main thread.** → They move to the main actor and compare the process before stopping anything.
- **A paused session looks almost off.** → The text stays next to the outlined cup, and the status line says "Paused on battery".
- **Notification identity for an ad-hoc-signed app.** A new build has a new signature, and macOS might ask for permission again after an update. → This is checked by hand on the installed release. Weiki keeps working without notifications.
- **The deep link into System Settings is undocumented.** → Fall back to the Notifications page.
- **The power source changes during sleep.** → Weiki reads it again on wake.
- **These choices were assumed while drafting, because the user didn't specify them:**
  - Only Dock apps are listed.
  - The app's name, cut to 10 characters, appears in the menu bar.
  - A UPS on battery counts as battery.
  - Notifications are sent for timers only.
  - The "Paused on battery" wording.

  → Confirm or change them when reviewing this draft, before applying it.

## Open Questions

- The notification's exact wording.
- Whether app icons in the submenu are worth it later. The specs only require names.
- *Answered (task 1.2):* a SwiftUI `Menu` inside the `.menu`-style content becomes a real submenu, and its items follow an `@Observable` list that changes while the menu is closed. A throwaway build listed "Finder, Google Chrome, iTerm2, Obsidian, Script Editor", which System Events read from the submenu. TextEdit appeared after it launched and was gone after it quit. No fallback is needed.
