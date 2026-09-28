import AppIntents
import AppKit

// Shortcuts actions. Each one works on the menu's own controller (`AppDependencyManager`, set up
// in `WeikiApp`), so a session from Shortcuts follows every rule a menu session does. The logic
// that decides what to start lives in `ShortcutActions`, where it's tested.

/// "Keep Mac Awake": indefinitely, or for a duration from 1 minute to 24 hours.
struct KeepMacAwakeIntent: AppIntent {
    static let title: LocalizedStringResource = "Keep Mac Awake"
    static let description = IntentDescription(
        "Keeps the Mac awake indefinitely, or for a duration from 1 minute to 24 hours, replacing any Weiki session."
    )

    @Parameter(title: "Duration", description: "Leave it empty to keep the Mac awake until you turn Weiki off.")
    var duration: Measurement<UnitDuration>?

    static var parameterSummary: some ParameterSummary {
        When(\.$duration, .hasAnyValue) {
            Summary("Keep Mac awake for \(\.$duration)")
        } otherwise: {
            Summary("Keep Mac awake indefinitely, or for \(\.$duration)")
        }
    }

    @Dependency private var controller: AwakeController

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ShortcutActions.keepAwake(forSeconds: duration?.converted(to: .seconds).value, on: controller)
        return .result(dialog: controller.statusDialog)
    }
}

/// "Keep Mac Awake Until App Quits": as if the app were chosen in the menu's submenu.
struct KeepMacAwakeUntilAppQuitsIntent: AppIntent {
    static let title: LocalizedStringResource = "Keep Mac Awake Until App Quits"
    static let description = IntentDescription(
        "Keeps the Mac awake until the app quits, replacing any Weiki session. The app must be running."
    )

    @Parameter(title: "App")
    var app: RunningAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Keep Mac awake until \(\.$app) quits")
    }

    @Dependency private var controller: AwakeController

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try ShortcutActions.keepAwake(untilQuit: app.id, named: app.name, among: NSWorkspace.shared.runningApplications, on: controller)
        return .result(dialog: controller.statusDialog)
    }
}

/// "Turn Off Weiki": ends the session, if one is active, as Turn Off in the menu does.
struct TurnOffWeikiIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Off Weiki"
    static let description = IntentDescription("Ends Weiki's session, if one is active, as Turn Off in the menu does.")

    @Dependency private var controller: AwakeController

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        controller.stop()
        return .result(dialog: controller.statusDialog)
    }
}

/// "Is Weiki Keeping the Mac Awake?": true only while a session holds the Mac awake.
struct IsWeikiKeepingTheMacAwakeIntent: AppIntent {
    static let title: LocalizedStringResource = "Is Weiki Keeping the Mac Awake?"
    static let description = IntentDescription(
        "Returns true while Weiki holds the Mac awake, and false while it's off or paused on battery."
    )

    @Dependency private var controller: AwakeController

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        .result(value: controller.state.isHolding, dialog: controller.statusDialog)
    }
}

/// An app, as a Shortcuts parameter. Its bundle identifier is its ID, so a saved shortcut finds
/// the app again in a later launch.
struct RunningAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "App"
    static let defaultQuery = RunningAppQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct RunningAppQuery: EntityQuery {
    /// The running apps with a Dock icon, as the menu's submenu lists them, once each.
    @MainActor
    func suggestedEntities() async throws -> [RunningAppEntity] {
        var suggested = Set<String>()
        return RunningApps.dockApps().compactMap { app in
            guard let id = app.bundleIdentifier, suggested.insert(id).inserted else { return nil }
            return RunningAppEntity(id: id, name: app.name)
        }
    }

    /// The apps saved shortcuts name. Each one resolves, even when it isn't running or
    /// installed, so the action can say which app isn't running.
    @MainActor
    func entities(for identifiers: [String]) async throws -> [RunningAppEntity] {
        let runningApps = NSWorkspace.shared.runningApplications
        return identifiers.map { id in
            let name = ShortcutActions.newestInstance(of: id, among: runningApps)?.name
                ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)?.deletingPathExtension().lastPathComponent
                ?? id
            return RunningAppEntity(id: id, name: name)
        }
    }
}

private extension AwakeController {
    /// What every action answers with: the status line, as the menu shows it.
    var statusDialog: IntentDialog {
        "\(state.statusLine(now: .now))"
    }
}

/// The phrases Siri and Spotlight offer without any setup.
struct WeikiShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: KeepMacAwakeIntent(),
            phrases: ["Keep my Mac awake with \(.applicationName)"],
            shortTitle: "Keep Mac Awake",
            systemImageName: "cup.and.saucer.fill"
        )
        AppShortcut(
            intent: TurnOffWeikiIntent(),
            phrases: ["Turn off \(.applicationName)"],
            shortTitle: "Turn Off",
            systemImageName: "cup.and.saucer"
        )
        AppShortcut(
            intent: IsWeikiKeepingTheMacAwakeIntent(),
            phrases: ["Is \(.applicationName) on?"],
            shortTitle: "Is Weiki On?",
            systemImageName: "questionmark.circle"
        )
    }
}
