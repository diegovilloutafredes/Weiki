# Proposal

## Why

Keeping the Mac awake today means running `caffeinate` in a terminal and remembering to stop it; nothing shows at a glance whether the Mac is being held awake or until when. Weiki puts that control in the menu bar, one click away, with its state always visible. It uses the same system mechanism `caffeinate` uses and is built on the same stack as the author's other menu bar app.

## What Changes

- New macOS menu bar app **Weiki** in a new repository (this is its first change).
- Keep-awake sessions: indefinitely or for 15 minutes, 1 hour, 2 hours, or a custom duration. A session ends when the user turns it off, when its time runs out, or when Weiki quits.
- Two modes, chosen with a "Keep Display On" setting that is on by default and remembered: keep the display and the system awake (like `caffeinate -d`), or keep only the system awake and let the display turn off (like `caffeinate -i`).
- Menu bar interface: a cup icon (outlined when off, filled when on) whose pull-down menu shows the current state (for example "Awake until 14:35") and holds every control. A small window lets the user enter a custom duration.
- While a session is active, the menu bar shows what's left next to the cup: ∞ for an indefinite session, or the time left counting down by the minute (for example "42m"). In the menu, the option that started the session has a checkmark.
- Weiki holds the Mac awake the same way `caffeinate` does, directly, without launching `caffeinate`. The hold appears as "Weiki" in `pmset -g assertions` and in Activity Monitor.
- Project scaffolding: XcodeGen project, Makefile, and automated tests.

Explicitly not in this change:
- Keeping the Mac awake with the lid closed, and preventing sleep from the Apple menu or a low battery. macOS does not let an app's sleep hold override these; closed-lid operation would need `sudo pmset disablesleep` and a privileged helper.
- Later layers: until an app quits, only while on AC power, launch at login, a notification when a timer ends, and a list of other processes preventing sleep.
- Localization, a custom app icon, and the signing, notarization, release, and auto-update pipeline.

## Capabilities

### New Capabilities

- `keep-awake`: Keep-awake sessions. Covers indefinite and timed sessions, replacing and ending them, display versus system-only mode and its persistence, how quitting and relaunching behave, how the hold appears to system tools, and what happens when the system refuses the hold.
- `menu-bar-controls`: The menu bar interface. Covers the icon and its states, the status line, the menu items (Turn Off, the duration choices, Keep Display On, Quit), and the Custom duration window.

### Modified Capabilities

None. This is the first change in a new repository.

## Impact

- **Code:** a new repository at `Personal/Apps/Weiki`; everything in it is new.
- **System:** creates and releases power assertions only. It needs no administrator privileges, no network access, no sandbox entitlements, and no third-party dependencies.
- **Requirements:** macOS 15 or later, and Xcode 26 or later (Swift 6).
