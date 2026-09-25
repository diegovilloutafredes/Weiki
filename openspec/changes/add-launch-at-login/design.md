# Design

## Context

See `proposal.md` for why. Weiki's menu is a SwiftUI `MenuBarExtra` whose content re-renders only when observed state changes (see the `add-keep-awake-menu` design, Decision 7). The author's other menu bar app implements the same feature with `SMAppService.mainApp` plus a stored preference that defaults to on. Apple's documentation confirms the following:
- `SMAppService.mainApp` and `register()` / `unregister()` are available on macOS 13+, and both can throw. Unregistering an item that isn't registered throws `kSMErrorJobNotFound`.
- `status` is one of `notRegistered`, `enabled`, `requiresApproval`, or `notFound`.
- `openSystemSettingsLoginItems()` opens the Login Items page.
- Unregistering the main app does not quit it.

## Goals / Non-Goals

**Goals:**
- The checkmark never disagrees with macOS at the moments Weiki reads the state: at launch and after each toggle.
- Unit tests never register the real app as a login item.

**Non-Goals:**
- Watching System Settings for changes while Weiki runs (see Risks).
- A settings window: the option lives in the menu, like "Keep Display On".

## Decisions

### 1. macOS is the source of truth
`SMAppService.mainApp.status` decides the checkmark: `enabled` shows it, anything else doesn't. There is no UserDefaults key.
- **Alternative:** a stored preference, as in the author's other menu bar app. It exists there only because that app opts in on first launch. With off by default, a stored preference could only disagree with the system.

### 2. A seam over ServiceManagement
`LoginItemService` exposes `status`, `register()`, `unregister()`, and `openSystemSettings()`. Its only production implementation is `SystemLoginItem`, a wrapper over `SMAppService.mainApp`, and that is the only file that imports ServiceManagement. It maps `.enabled` to enabled, `.requiresApproval` to requires-approval, and `.notRegistered` and `.notFound` to off.

`LoginItem` is `@Observable` and runs on the main actor. It holds `isEnabled`, read at init and read again after each change. Tests use a recording fake, because registering during `make test` would add the test host (Weiki itself) as a real login item.

### 3. Toggling
`setEnabled(true)` calls `register()`, and `setEnabled(false)` calls `unregister()`. A thrown error is ignored beyond what the status then reports, because the status is the truth. For example, unregistering an item that is already gone throws, and a refused registration leaves the status at off or requires-approval. If the status is requires-approval after turning the item on, `openSystemSettingsLoginItems()` opens System Settings.

### 4. Menu item
A `Toggle("Launch at Login")` goes below "Keep Display On". It is bound to `isEnabled`, and its setter calls `setEnabled`. `WeikiApp` owns the `LoginItem` as `@State`, next to the controller.

## Risks / Trade-offs

- **Changes made in System Settings while Weiki runs don't show until the next toggle or relaunch.** The menu only redraws on observed changes, and macOS posts no notification for login-item changes. → Acceptable; documented in the project notes.
- **Registration records the app's current location.** → `make run` installs to `/Applications` before launching. A copy run from somewhere else would register that path.

## Migration Plan

None needed: this is a new option, off by default. To undo it, uncheck the item or remove Weiki in System Settings.
