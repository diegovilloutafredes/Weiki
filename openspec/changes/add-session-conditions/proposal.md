# Proposal

## Why

Layer 1 keeps the Mac awake indefinitely or for a set time, and launch at login already shipped from layer 2. The rest of layer 2 covers three situations a fixed duration handles badly. A long job in some app has no known end. A forgotten session can drain the battery. And the user doesn't find out when a timed session has run out.

## What Changes

- **Until an App Quits.** "Keep Awake For" gains an "Until an App Quits" submenu that lists the running apps that appear in the Dock. Choosing one keeps the Mac awake until that app quits, including if it crashes or is force-quit. The status line reads "Awake until Xcode quits", and the menu bar shows the app's name next to the cup.
- **Only on AC Power.** A new setting, off by default and remembered across launches. While it's on and the Mac runs on battery, the active session pauses: Weiki releases its hold, and the session keeps its end time. When the Mac is plugged in again, the session resumes. While a session is paused, the cup is outlined and the status line starts with "Paused on battery".
- **Notify When Time's Up.** A new setting, off by default and remembered. Turning it on asks macOS for permission to show notifications. While it's on, a timed session that runs out posts a notification. Other endings post nothing.

Not in this change: notifications for other endings, a battery-level threshold, and layer 3 (the list of other processes that hold sleep assertions).

## Capabilities

### New Capabilities

- `until-app-quits`: The "Until an App Quits" submenu, sessions tied to one running app, and how they end and show.
- `ac-power-only`: The "Only on AC Power" setting, and how sessions pause on battery, resume on AC power, and show while paused.
- `end-notification`: The "Notify When Time's Up" setting, macOS's notification permission, and the notification posted when a timed session runs out.

### Modified Capabilities

- `menu-bar-controls`: "Keep Awake For" gains the submenu. The cup is outlined while a session is paused. The menu bar shows the app's name during an "until an app quits" session.

`keep-awake` keeps its requirements. `ac-power-only` states that pausing takes precedence over every requirement that keeps the Mac awake.

## Impact

- **Order:** `menu-bar-controls` exists only in `add-keep-awake-menu` until that change is archived, and archive refuses a MODIFIED delta without a main spec. So archive `add-keep-awake-menu` first (after its manual check, task 7.3). Its deltas become the main specs this change modifies.
- **Code:** the session model (a third kind of session, and a paused state), the menu, the menu bar label, and the status line. New code for the list of running apps, for the power source, and for notifications. Notifications add the UserNotifications framework, which is part of macOS. There is still no third-party dependency.
- **Permissions:** macOS asks for notification permission the first time "Notify When Time's Up" is turned on. Watching an app quit and reading the power source need no permission.
- **Settings:** two new remembered settings, next to `keepsDisplayOn`.
