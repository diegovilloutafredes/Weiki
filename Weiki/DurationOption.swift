import Foundation

/// The menu's "Keep Awake For" choices.
enum DurationOption: Hashable {
    case indefinitely
    case fifteenMinutes
    case oneHour
    case twoHours
    case custom(TimeInterval)

    /// How long a session started from this option lasts, in seconds; nil for no end.
    var duration: TimeInterval? {
        switch self {
        case .indefinitely: nil
        case .fifteenMinutes: 15 * 60
        case .oneHour: 60 * 60
        case .twoHours: 2 * 60 * 60
        case .custom(let seconds): seconds
        }
    }
}
