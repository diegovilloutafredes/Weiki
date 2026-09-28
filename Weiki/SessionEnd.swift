import Foundation

/// When a session ends.
enum SessionEnd: Hashable {
    /// No end of its own: it lasts until it's turned off or replaced, or Weiki quits.
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
struct WatchedApp: Hashable, Identifiable {
    let processIdentifier: pid_t
    let name: String
    /// How a shortcut finds the app again in a later launch; nil for the rare app without one.
    var bundleIdentifier: String?

    var id: pid_t { processIdentifier }
}
