import Foundation

// Defaults are `.autoupdatingCurrent`, not `.current`: the system time zone is cached per
// process, and only the autoupdating values follow a time zone or locale change.

extension AwakeController.State {
    /// The menu's first line, for example "Awake until 14:35" or "Paused on battery, until
    /// Xcode quits". The time follows the locale's clock, and the weekday is added when the
    /// end isn't on the same day as `now`.
    func statusLine(now: Date, calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        switch self {
        case .off:
            String(localized: "Weiki is off")
        case .on(until: .never, paused: false):
            String(localized: "Awake indefinitely")
        case .on(until: .date(let endDate), paused: false):
            String(localized: "Awake until \(endDate.endTimeDescription(now: now, calendar: calendar, locale: locale))")
        case .on(until: .appQuits(let app), paused: false):
            String(localized: "Awake until \(app.name) quits")
        case .on(until: .never, paused: true):
            String(localized: "Paused on battery")
        case .on(until: .date(let endDate), paused: true):
            String(localized: "Paused on battery, until \(endDate.endTimeDescription(now: now, calendar: calendar, locale: locale))")
        case .on(until: .appQuits(let app), paused: true):
            String(localized: "Paused on battery, until \(app.name) quits")
        }
    }

    /// The text after the cup in the menu bar: "∞", the time left ("42m"), or the app the
    /// session waits for. Nil while off. A paused session keeps its text; only the cup changes.
    func menuBarText(minutesLeft: Int?, locale: Locale = .autoupdatingCurrent) -> String? {
        switch self {
        case .off: nil
        case .on(until: .never, _): "∞"
        case .on(until: .date, _): minutesLeft.map { timeLeftText(minutes: $0, locale: locale) }
        case .on(until: .appQuits(let app), _): menuBarName(app.name)
        }
    }
}

/// An app's name as the menu bar shows it: up to 10 characters, then "…" with no space before it.
private func menuBarName(_ name: String) -> String {
    guard name.count > 10 else { return name }
    return name.prefix(10).trimmingCharacters(in: .whitespaces) + "…"
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
