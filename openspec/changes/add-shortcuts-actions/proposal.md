# Proposal

## Why

Everything Weiki does today starts with a click in its menu. Shortcuts actions let people start and stop sessions from Siri, Spotlight, and the Shortcuts app, and give them a keyboard shortcut, which the Shortcuts app can assign to any shortcut. On macOS 26 and later, Shortcuts automations can also run those actions at a time of day, when an app opens, when a display connects, when a Focus mode starts, or at a battery level. That gives Weiki schedules and "keep awake while…" rules without building a trigger system of its own.

## What Changes

- Four actions in the Shortcuts app:
  - **Keep Mac Awake**, indefinitely or for a duration from 1 minute to 24 hours.
  - **Keep Mac Awake Until App Quits**, for a running app.
  - **Turn Off Weiki**.
  - **Is Weiki Keeping the Mac Awake?**, which returns true or false.
- A session started from Shortcuts behaves exactly like one started from the menu: it replaces any active session, and it follows "Keep Display On" and "Only on AC Power". The menu checks the matching option.
- Ready-made phrases for Siri and Spotlight: "Keep my Mac awake with Weiki", "Turn off Weiki", and "Is Weiki on?".
- A Shortcuts section in the README.

Not in this change: an action that changes Weiki's settings, a "until a time" action, and searching installed apps that aren't running.

## Capabilities

### New Capabilities

- `shortcuts-actions`: The Shortcuts actions, how their sessions relate to the menu, their errors, and the phrases for Siri and Spotlight.

### Modified Capabilities

None. The actions start and end sessions through the existing rules in `keep-awake`, `until-app-quits`, and `ac-power-only`.

## Impact

- **Order:** apply after `add-session-conditions`, because "Keep Mac Awake Until App Quits" and the paused state come from it. This change adds only new requirements, so it can be archived on its own.
- **Code:** a thin set of app intents over `AwakeController`, and an entity for running apps. It uses the App Intents framework, which is part of macOS, so there is still no third-party dependency.
- **System:** Shortcuts, Siri, and Spotlight list Weiki's actions once the app is installed. Running an action launches Weiki in the menu bar if it isn't running. No permission is needed.
