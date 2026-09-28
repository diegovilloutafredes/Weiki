import Foundation

/// Why a Shortcuts action couldn't do what it was asked. Shortcuts shows the message.
enum ShortcutError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case durationOutOfRange
    case appNotRunning(String)
    /// No session is on after starting one: macOS refused the hold, or the app quit meanwhile.
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

    /// "Keep Mac Awake Until App Quits": `app` is the running copy, or nil when none runs.
    static func keepAwake(until app: WatchedApp?, named name: String, on controller: AwakeController) throws(ShortcutError) {
        guard let app else { throw .appNotRunning(name) }
        try start(.untilQuit(app), on: controller)
    }

    /// The menu's presets stand for their exact lengths, so the menu checks them.
    private static func option(forSeconds seconds: TimeInterval?) throws(ShortcutError) -> DurationOption {
        guard let seconds else { return .indefinitely }
        guard (60...24 * 60 * 60).contains(seconds) else { throw .durationOutOfRange }
        return switch seconds {
        case 15 * 60: .fifteenMinutes
        case 60 * 60: .oneHour
        case 2 * 60 * 60: .twoHours
        default: .custom(seconds)
        }
    }

    /// Starts `option`, replacing any session, and fails when no session is on afterwards, so
    /// a shortcut never reports a session that isn't there. A paused session counts as on.
    private static func start(_ option: DurationOption, on controller: AwakeController) throws(ShortcutError) {
        controller.start(option)
        guard controller.state != .off else { throw .couldNotStart }
    }
}
