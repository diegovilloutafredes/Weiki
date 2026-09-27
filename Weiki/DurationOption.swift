import Foundation

/// The menu's "Keep Awake For" choices.
enum DurationOption: Hashable {
    case indefinitely
    case fifteenMinutes
    case oneHour
    case twoHours
    case custom(TimeInterval)
    case untilQuit(WatchedApp)

    /// When a session started from this option at `start` ends.
    func end(startingAt start: Date) -> SessionEnd {
        switch self {
        case .indefinitely: .never
        case .fifteenMinutes: .date(start.addingTimeInterval(15 * 60))
        case .oneHour: .date(start.addingTimeInterval(60 * 60))
        case .twoHours: .date(start.addingTimeInterval(2 * 60 * 60))
        case .custom(let seconds): .date(start.addingTimeInterval(seconds))
        case .untilQuit(let app): .appQuits(app)
        }
    }
}
