# Tasks

## 1. Before starting

- [x] 1.1 Check that `add-session-conditions` is applied: `SessionEnd`, the paused state, and `RunningApps` exist. Verify that `make test` passes.
- [ ] 1.2 Add one real intent, "Turn Off Weiki", with the controller shared through `AppDependencyManager` (design Decisions 2 and 3), and settle the concurrency question from Risks. Verify three things. First, `make build` has no warnings. Second, the built bundle contains `Metadata.appintents`. Third, after `make run`, the Shortcuts app lists the action, and running it ends a session both while Weiki is running and after quitting it (Weiki relaunches in the menu bar with no window). Record the answers under Open Questions in `design.md`.

  Done so far:
  - `make build` has no warnings.
  - `Metadata.appintents` lists `TurnOffWeikiIntent`.
  - Shortcuts' action library finds "Turn Off Weiki" when searched for "Weiki", so the system picks up the ad-hoc-signed build's intents.

  Still to do by hand: running the action from a shortcut, both while Weiki runs and after it quits. The Shortcuts editor couldn't be driven through Accessibility, because its action rows expose no actions.

## 2. The actions

- [x] 2.1 Write the `ShortcutActions` tests first, with a controller built on the recording power-assertion fake:
  - no duration starts an indefinite session and selects `.indefinitely`
  - 15 minutes, 1 hour, and 2 hours select their presets, and other durations from 1 minute to 24 hours select `.custom`
  - an action replaces an active session
  - durations under 1 minute or over 24 hours throw and leave the active session as it was
  - an app that isn't running throws an error that names it, and changes nothing
  - a refused hold makes the action throw, so it never reports a session that isn't there
  - `RunningApps.newestInstance(of:among:)` finds the newest running copy of an app, with or without a Dock icon
  - ("Turn Off Weiki" is `stop()`, and the status action returns `state.isHolding`, both covered by the controller tests.)

  Then implement `ShortcutActions` and `ShortcutError` (design Decisions 1 and 5). Verify that `make test` passes.
- [ ] 2.2 Add the four intents, `RunningAppEntity` with its query, and `WeikiShortcuts` (design Decisions 4 to 6). Verify in the Shortcuts app, with `pmset -g assertions`, every scenario in `specs/shortcuts-actions` that doesn't need Siri: each action and its result, the error messages, the suggested apps, and a saved shortcut still naming an app after the app quits.

  Done so far:
  - The build's `Metadata.appintents` has the four actions, `RunningAppEntity` with `RunningAppQuery`, and the three phrases.
  - Shortcuts' action library lists all four actions under "Weiki".

  Still to do by hand: running them in Shortcuts. The editor's rows can't be driven through Accessibility, and a test shortcut can't be imported without signing it, which needs an iCloud sign-in.
- [ ] 2.3 By hand (needs a person):
  - Say "Keep my Mac awake with Weiki" and "Is Weiki on?" to Siri.
  - Run Weiki's actions from Spotlight on macOS 26.
  - Assign a keyboard shortcut to a "Keep Mac Awake" shortcut in the Shortcuts app and use it.
  - On macOS 26, create the automation "When TextEdit opens → Keep Mac Awake Until App Quits: TextEdit" and check that it works.
- [x] 2.4 Add a Shortcuts section to the README: the four actions, the phrases, keyboard shortcuts through the Shortcuts app, and automations on macOS 26. Add the intents, `ShortcutActions`, and the dependency registration to the project notes. Verify that the text matches the code and that both of the project notes' pre-push checks print nothing.

## 3. Integration

- [x] 3.1 Run `make clean generate test run`, then walk through the scenarios again against the installed build. Verify that `openspec validate add-shortcuts-actions --strict` succeeds, and that `make build` and `make test` pass with no warnings.

  After a clean build, the installed app's metadata lists the four actions, Shortcuts' library finds them, and the menu and sessions work as before. Running the actions in Shortcuts is covered by the manual tasks 1.2, 2.2, and 2.3. A code review of this change found ten points, and all are fixed:
  - an action fails when no session is on afterwards
  - saved apps always resolve, with their proper name
  - the newest running copy is used, with or without a Dock icon
  - suggestions don't repeat
  - the lookups are shared
  - the empty-duration summary reads correctly
  - the tests cover the controller-level cases
  - the design matches the code
