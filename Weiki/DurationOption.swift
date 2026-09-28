import Foundation

/// The menu's "Keep Awake For" choices.
enum DurationOption: Hashable {
    case indefinitely
    case fifteenMinutes
    case oneHour
    case twoHours
    case custom(TimeInterval)
    case untilQuit(WatchedApp)

    /// The fixed-length choices, in menu order.
    static let presets: [DurationOption] = [.fifteenMinutes, .oneHour, .twoHours]

    /// The lengths a custom session may have: 1 minute to 24 hours.
    static let customRange: ClosedRange<TimeInterval> = 60...24 * 60 * 60

    /// How long a session started from this option lasts; nil when it has no set length.
    var duration: TimeInterval? {
        switch self {
        case .indefinitely, .untilQuit: nil
        case .fifteenMinutes: 15 * 60
        case .oneHour: 60 * 60
        case .twoHours: 2 * 60 * 60
        case .custom(let seconds): seconds
        }
    }

    /// When a session started from this option at `start` ends.
    func end(startingAt start: Date) -> SessionEnd {
        if case .untilQuit(let app) = self { return .appQuits(app) }
        return duration.map { .date(start.addingTimeInterval($0)) } ?? .never
    }
}
