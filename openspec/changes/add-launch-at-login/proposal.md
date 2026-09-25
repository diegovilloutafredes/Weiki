# Proposal

## Why

Weiki only helps while it is running, and today it has to be opened by hand after every restart or login. An opt-in "Launch at Login" option, like the one in the author's other menu bar app, keeps it in the menu bar without the user having to remember it.

## What Changes

- A "Launch at Login" checkmark item in the menu, below "Keep Display On".
- Choosing it registers or unregisters Weiki as a login item with macOS. The checkmark mirrors what macOS reports; Weiki stores no preference of its own.
- Off by default: Weiki never registers itself.
- When macOS needs the user's approval (Weiki was switched off in System Settings > General > Login Items), choosing the item opens that page.

Not in this change: the rest of layer 2 (until an app quits, only while on AC power, and a notification when a timer ends).

## Capabilities

### New Capabilities

- `launch-at-login`: The opt-in login item. Covers the menu item, how it registers and unregisters Weiki, how its checkmark follows macOS's login-item state, and the case where macOS needs the user's approval.

### Modified Capabilities

None.

## Impact

- **Code:** a small login-item model and its menu item, using ServiceManagement (`SMAppService.mainApp`), which is part of macOS. There is no new dependency.
- **System:** when enabled, Weiki appears in System Settings > General > Login Items. Unit tests never touch the real login item.
