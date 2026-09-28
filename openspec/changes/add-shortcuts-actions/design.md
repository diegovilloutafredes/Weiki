# Design

## Context

See `proposal.md`. After `add-session-conditions`, `AwakeController` holds the session (`State` with `SessionEnd` and `paused`), and `RunningApps` lists the running Dock apps. The app owns one controller in `WeikiApp`.

Facts established before writing this design (App Intents documentation):

- An app registers shared objects with `AppDependencyManager.shared.add(dependency:)` when it starts, and an intent reads them through `@Dependency` properties.
- `perform()` can be `@MainActor`. It runs after the system resolves the parameters, and it returns a result or throws.
- `AppShortcutsProvider` phrases must contain `\(.applicationName)`. They are what Siri and Spotlight offer without any setup.
- An `AppEntity` parameter gets its choices from its query: `suggestedEntities()` for suggestions, and `entities(for:)` to turn stored IDs back into entities.
- `static var supportedModes` (foreground or background) is new in macOS 26. An intent in the app itself, with the default mode, runs in the app's process, and the app is launched if it isn't running.

## Goals / Non-Goals

**Goals:**
- A session from Shortcuts is indistinguishable from one started in the menu: same rules, same hold, same checkmark.
- The testable logic stays in plain Swift. The intents are glue, checked by hand in Shortcuts.

**Non-Goals:**
- An App Intents extension. Weiki is a small menu bar agent that is usually running, and launching it is cheap.
- Parameterized phrases for Siri (for example "for 30 minutes"). The Shortcuts app covers durations.

## Decisions

### 1. Thin intents over tested functions
`ShortcutActions` holds what each action does:
- `keepAwake(forSeconds:on:)` checks the duration first: nil means `.indefinitely`, the range is 60 seconds to 24 hours, the three presets match exactly, and anything else is `.custom`.
- `keepAwake(untilQuit:named:among:on:)` finds the running copy of the app with that bundle identifier (Decision 4), and fails with the app's name when there is none.

Both then start the session and fail with `.couldNotStart` when `start` reports that no session is on afterwards: macOS refused the hold, or the app quit meanwhile. This way a shortcut never reports a session that isn't there, and an automation can't carry on while the Mac sleeps. A paused session counts as on. Because the input is checked first, a failed action leaves the session as it was.

Each intent reads the controller through `@Dependency`, calls one of these (or `stop()`), and answers with the status line. "Is Weiki Keeping the Mac Awake?" returns `state.isHolding`. The unit tests call `ShortcutActions` with a controller built on fakes. They never go through `@Dependency`, because the test host is Weiki itself and has already registered the real controller.
- *Alternative:* the logic inside `perform()`. Rejected, because it can't be tested without the App Intents runtime.

### 2. Sharing the controller
`WeikiApp.init` creates the controller, stores it in its `@State` (through `State(initialValue:)`), and registers the same instance with `AppDependencyManager`. There is one controller, so the menu and the actions always agree. Nothing else is registered: the actions read running apps from `NSWorkspace` when they run.

### 3. How the intents run
They use the default mode: no `openAppWhenRun` and no `supportedModes`. The system runs them in Weiki's process and launches Weiki first if it isn't running. As a menu bar agent it opens no window, which matches the spec. Setting `supportedModes` would need an availability check, because it only exists from macOS 26, and it isn't needed.

### 4. The app parameter
`RunningAppEntity` uses the bundle identifier as its ID, so a saved shortcut finds the app again in a later launch. `WatchedApp` carries the bundle identifier for this.
- `suggestedEntities()` lists the running apps with a Dock icon, once per bundle identifier, as the submenu does.
- `entities(for:)` always resolves an ID. The name comes from the newest running copy, otherwise from the installed app's file name without ".app", otherwise the ID itself. It doesn't use `FileManager.displayName`, which would read "Keynote.app" when Finder shows extensions.
- When the action runs, `ShortcutActions.newestInstance(of:among:)` finds the running copy launched last, with or without a Dock icon. That covers an app that hides its Dock icon, and an automation that fires as the app opens. If there is none, the action fails with "Keynote isn't running."

### 5. Errors and results
- **Errors:** `ShortcutError` conforms to `CustomLocalizedStringResourceConvertible`, so Shortcuts shows its message:
  - "Choose a duration from 1 minute to 24 hours."
  - "\(app) isn't running."
  - "Weiki couldn't keep the Mac awake."
- **Results:** every action returns a dialog with the status line. The status action also returns `ReturnsValue<Bool>`, so it can drive an "If" in Shortcuts.
- **Duration parameter:** a `Measurement<UnitDuration>`. Its summary reads "Keep Mac awake for 30 min" when it's set, and "Keep Mac awake indefinitely, or for Duration" when it's empty.

### 6. Phrases
`WeikiShortcuts: AppShortcutsProvider` offers three App Shortcuts:
- "Keep my Mac awake with \(.applicationName)", running Keep Mac Awake with no duration
- "Turn off \(.applicationName)"
- "Is \(.applicationName) on?"

Each gets a short title and an SF Symbol: `cup.and.saucer.fill`, `cup.and.saucer`, and `questionmark.circle`.

## Risks / Trade-offs

- **Default MainActor isolation and the `AppIntent` conformances.** The project isolates types to the main actor by default, and the framework's requirements may need nonisolated types. → The first task builds one intent before anything else. If it fails, the intent types become `nonisolated` with a `@MainActor perform()`.
- **Shortcuts finding the actions in an ad-hoc-signed app.** → Checked by hand after installing the release build. Xcode extracts the metadata at build time (`Metadata.appintents`), and the task checks that the bundle contains it.
- **An automation fires while Weiki is quitting or launching.** → The system launches Weiki as needed. The actions have no state of their own.
- **macOS 15 has no Shortcuts automations.** The actions still work from the Shortcuts app, Siri, and Spotlight search. → The README says automations need macOS 26.

## Open Questions

- *Answered (a spike for task 1.2):* the project's default main-actor isolation is no problem. A plain `struct TurnOffWeikiIntent: AppIntent` with `@Dependency private var controller: AwakeController` and a `@MainActor` `perform()` built with no warnings, so no `nonisolated` is needed. Xcode wrote `Metadata.appintents/extract.actionsdata` into the bundle, listing the action as "Turn Off Weiki" with `openAppWhenRun: false`, and XcodeGen needs no settings for it.
- Searching installed apps (not just running ones) for the app parameter.
- A "Set Keep Display On" action, if automations turn out to need one.
- *Answered:* Apple's App Intents Testing framework can't replace task 2.2's manual checks yet. It needs macOS 27 and Xcode 27, and it runs from a UI-test target that launches the app (`XCUIApplication` plus `IntentDefinitions(bundleIdentifier:)`). CI builds with Xcode 26.5, so the logic stays in `ShortcutActions`, with plain unit tests.
