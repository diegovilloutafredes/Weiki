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

### 1. Thin intents over pure decisions
`ShortcutActions` holds the decisions as pure functions that return the `DurationOption` to start, or throw a typed `ShortcutError`:
- `option(forSeconds:)`: nil means `.indefinitely`, the range is 60 seconds to 24 hours, the three presets match exactly, and anything else is `.custom`.
- `option(untilQuit:named:among:)`: finds a running app by bundle identifier, or throws `.appNotRunning(name)`.

Each intent reads the controller through `@Dependency`, calls `controller.start(try …)` (or `stop()`), and answers with the status line. "Is Weiki Keeping the Mac Awake?" returns `state.isHolding`. Unit tests call `ShortcutActions` directly and never go through `@Dependency`, because the test host is Weiki itself and has already registered the real controller. `stop()` and `isHolding` are covered by the controller tests.

`WatchedApp` gains an optional `bundleIdentifier`, which `RunningApps.dockApps(from:)` fills in, so a shortcut can find an app again in a later launch.
- *Alternative:* an extension on `AwakeController` with `keepAwake(for:)` and so on. Rejected: it would mix the input rules with the session, and each test would need a controller.

### 2. Sharing the controller
`WeikiApp.init` creates the controller and `RunningApps`, stores them in its `@State` (through `State(initialValue:)`), and registers the same instances with `AppDependencyManager`. There is one controller, so the menu and the actions always agree.

### 3. How the intents run
They use the default mode: no `openAppWhenRun` and no `supportedModes`. The system runs them in Weiki's process and launches Weiki first if it isn't running. As a menu bar agent it opens no window, which matches the spec. Setting `supportedModes` would need an availability check, because it only exists from macOS 26, and it isn't needed.

### 4. The app parameter
`RunningAppEntity` uses the bundle identifier as its ID and the app's name as its display name.
- `suggestedEntities()` returns the running Dock apps from `RunningApps`.
- `entities(for:)` resolves IDs to running apps and keeps the stored name for apps that aren't running, so a saved shortcut still shows "Keynote".
- When the action runs, the app must be running, or `perform()` throws "Keynote isn't running."

Only running apps can be picked while editing a shortcut. That's enough for the main automation, "When Keynote opens → Keep Mac Awake Until App Quits: Keynote", which is set up while Keynote is open. Searching installed apps is an open question.

### 5. Errors and results
- **Errors:** a `WeikiIntentError` enum that conforms to `CustomLocalizedStringResourceConvertible`, with two messages: "Choose a duration from 1 minute to 24 hours." and "\(app) isn't running."
- **Results:** every action returns a dialog with the status line after it runs ("Awake until 15:00", "Weiki is off"). The status action also returns `ReturnsValue<Bool>`, so it can drive an "If" in Shortcuts.
- **Duration parameter:** a `Measurement<UnitDuration>`, the type the Shortcuts editor shows as a duration picker.

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
