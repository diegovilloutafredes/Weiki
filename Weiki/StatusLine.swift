import Foundation

// Defaults are `.autoupdatingCurrent`, not `.current`: the system time zone is cached per
// process, and only the autoupdating values follow a time zone or locale change.

extension AwakeController.State {
    /// The menu's first line, for example "Awake until 14:35". The time follows the
    /// locale's clock, and the weekday is added when the end isn't on the same day as `now`.
    func statusLine(now: Date, calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        switch self {
        case .off:
            return String(localized: "Weiki is off")
        case .on(until: nil):
            return String(localized: "Awake indefinitely")
        case .on(until: let endDate?):
            let time = endDate.endTimeDescription(now: now, calendar: calendar, locale: locale)
            return String(localized: "Awake until \(time)")
        }
    }
}

/// The menu bar's countdown: whole minutes as the locale's narrow hours and minutes
/// ("42m", "1h 5m", "1h").
func timeLeftText(minutes: Int, locale: Locale = .autoupdatingCurrent) -> String {
    Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow).locale(locale))
}

extension Date {
    /// When a session ends: the time in the locale's clock ("14:35"), with the abbreviated
    /// weekday added when it isn't on the same day as `now` ("Fri 09:10").
    func endTimeDescription(now: Date, calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        if !calendar.isDate(self, inSameDayAs: now) {
            style = style.weekday(.abbreviated)
        }
        return formatted(style.hour().minute())
    }
}
