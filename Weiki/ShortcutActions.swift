import Foundation

/// Why a Shortcuts action couldn't start a session. Shortcuts shows the message.
enum ShortcutError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case durationOutOfRange
    case appNotRunning(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .durationOutOfRange: "Choose a duration from 1 minute to 24 hours."
        case .appNotRunning(let name): "\(name) isn't running."
        }
    }
}

/// The sessions the Shortcuts actions start, apart from the App Intents glue.
enum ShortcutActions {
    /// "Keep Mac Awake": indefinitely without a duration, or for 1 minute to 24 hours. The
    /// menu's presets stand for their exact lengths, so the menu checks them.
    static func option(forSeconds seconds: TimeInterval?) throws(ShortcutError) -> DurationOption {
        guard let seconds else { return .indefinitely }
        guard (60...24 * 60 * 60).contains(seconds) else { throw .durationOutOfRange }
        return switch seconds {
        case 15 * 60: .fifteenMinutes
        case 60 * 60: .oneHour
        case 2 * 60 * 60: .twoHours
        default: .custom(seconds)
        }
    }

    /// "Keep Mac Awake Until App Quits": the running app with `bundleIdentifier` among `apps`,
    /// or an error naming the app when it isn't running.
    static func option(untilQuit bundleIdentifier: String, named name: String, among apps: [WatchedApp]) throws(ShortcutError) -> DurationOption {
        guard let app = apps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else { throw .appNotRunning(name) }
        return .untilQuit(app)
    }
}
