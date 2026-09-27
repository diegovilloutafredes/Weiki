import Foundation

/// When a session ends.
enum SessionEnd: Hashable {
    /// Only Turn Off, or quitting Weiki, ends it.
    case never
    /// A timed session ends at this date.
    case date(Date)
    /// The session lasts until this app quits.
    case appQuits(WatchedApp)

    /// A timed session's end date; nil for the other kinds.
    var endDate: Date? {
        if case .date(let date) = self { date } else { nil }
    }
}

/// A running app a session can wait for: its process, and its name for the menu and the menu bar.
struct WatchedApp: Hashable {
    let processIdentifier: pid_t
    let name: String
}
