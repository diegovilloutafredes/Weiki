# Tasks

## 1. Before starting

- [ ] 1.1 Check that `add-session-conditions` is applied: `SessionEnd`, the paused state, and `RunningApps` exist. Verify that `make test` passes.
- [ ] 1.2 Add one real intent, "Turn Off Weiki", with the controller shared through `AppDependencyManager` (design Decisions 2 and 3), and settle the concurrency question from Risks. Verify three things. First, `make build` has no warnings. Second, the built bundle contains `Metadata.appintents`. Third, after `make run`, the Shortcuts app lists the action, and running it ends a session both while Weiki is running and after quitting it (Weiki relaunches in the menu bar with no window). Record the answers under Open Questions in `design.md`.

## 2. The actions

- [ ] 2.1 Write the `ShortcutActions` tests first, with the recording power-assertion fake and a test controller:
  - no duration starts an indefinite session and selects `.indefinitely`
  - 15 minutes, 1 hour, and 2 hours select their presets, and 45 minutes selects `.custom`
  - durations under 1 minute or over 24 hours throw and leave the state unchanged
  - an action replaces an active session
  - an app that isn't running throws an error that names it, and changes nothing
  - `turnOff()` ends a session and does nothing when off
  - `isKeepingAwake` is true while holding and false when off or paused

  Then implement `ShortcutActions` and `WeikiIntentError` (design Decisions 1 and 5). Verify that `make test` passes.
- [ ] 2.2 Add the four intents, `RunningAppEntity` with its query, and `WeikiShortcuts` (design Decisions 4 to 6). Verify in the Shortcuts app, with `pmset -g assertions`, every scenario in `specs/shortcuts-actions` that doesn't need Siri: each action and its result, the error messages, the suggested apps, and a saved shortcut still naming an app after the app quits.
- [ ] 2.3 By hand (needs a person):
  - Say "Keep my Mac awake with Weiki" and "Is Weiki on?" to Siri.
  - Run Weiki's actions from Spotlight on macOS 26.
  - Assign a keyboard shortcut to a "Keep Mac Awake" shortcut in the Shortcuts app and use it.
  - On macOS 26, create the automation "When TextEdit opens → Keep Mac Awake Until App Quits: TextEdit" and check that it works.
- [ ] 2.4 Add a Shortcuts section to the README: the four actions, the phrases, keyboard shortcuts through the Shortcuts app, and automations on macOS 26. Add the intents, `ShortcutActions`, and the dependency registration to the project notes. Verify that the text matches the code and that both of the project notes' pre-push checks print nothing.

## 3. Integration

- [ ] 3.1 Run `make clean generate test run`, then walk through the scenarios again against the installed build. Verify that `openspec validate add-shortcuts-actions --strict` succeeds, and that `make build` and `make test` pass with no warnings.
