import Foundation

/// Why a Shortcuts action couldn't do what it was asked. Shortcuts shows the message.
enum ShortcutError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case durationOutOfRange
    case appNotRunning(String)
    case couldNotStart

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .durationOutOfRange: "Choose a duration from 1 minute to 24 hours."
        case .appNotRunning(let name): "\(name) isn't running."
        case .couldNotStart: "Weiki couldn't keep the Mac awake."
        }
    }
}

/// What the Shortcuts actions do, apart from the App Intents glue. Each one checks its input
/// before touching the session, so a failed action leaves the session as it was.
enum ShortcutActions {
    /// "Keep Mac Awake": indefinitely without a duration, or for 1 minute to 24 hours.
    static func keepAwake(forSeconds seconds: TimeInterval?, on controller: AwakeController) throws(ShortcutError) {
        try start(option(forSeconds: seconds), on: controller)
    }

    /// "Keep Mac Awake Until App Quits": the newest running copy of the app with
    /// `bundleIdentifier`, or an error naming the app when none runs.
    static func keepAwake(
        untilQuit bundleIdentifier: String,
        named name: String,
        among runningApps: [some RunningAppInfo],
        on controller: AwakeController
    ) throws(ShortcutError) {
        guard let app = newestInstance(of: bundleIdentifier, among: runningApps) else { throw .appNotRunning(name) }
        try start(.untilQuit(app), on: controller)
    }

    /// The running copy of the app with `bundleIdentifier` that was launched last, with or
    /// without a Dock icon, or nil when none runs. That covers an app that hides its Dock icon,
    /// and an automation that fires as the app opens.
    static func newestInstance(of bundleIdentifier: String, among runningApps: [some RunningAppInfo]) -> WatchedApp? {
        runningApps
            .filter { $0.bundleIdentifier == bundleIdentifier }
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
            .flatMap { WatchedApp($0) }
    }

    /// A preset's exact length selects that preset, so the menu checks it.
    private static func option(forSeconds seconds: TimeInterval?) throws(ShortcutError) -> DurationOption {
        guard let seconds else { return .indefinitely }
        guard DurationOption.customRange.contains(seconds) else { throw .durationOutOfRange }
        return DurationOption.presets.first { $0.duration == seconds } ?? .custom(seconds)
    }

    /// Starts `option`, replacing any session. Fails when no session is on afterwards, so a
    /// shortcut never reports a session that isn't there. A paused session counts as on.
    private static func start(_ option: DurationOption, on controller: AwakeController) throws(ShortcutError) {
        guard controller.start(option) else { throw .couldNotStart }
    }
}
