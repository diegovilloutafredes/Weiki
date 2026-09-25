import Foundation
import Testing
@testable import Weiki

/// The Custom window's text field: which texts are durations, and the line below it.
struct CustomDurationTextTests {
    @Test(arguments: [
        ("45", 45),
        ("45m", 45),
        ("45 min", 45),
        ("90", 90),
        ("2h", 120),
        ("1h30", 90),
        ("1h 30m", 90),
        ("1H30M", 90),
        ("1:30", 90),
        ("0:45", 45),
        ("24h", 1440),
        (" 5m ", 5),
        ("1", 1),
    ])
    func acceptsDuration(text: String, minutes: Int) {
        #expect(CustomDurationView.duration(from: text) == TimeInterval(minutes * 60))
    }

    @Test(arguments: ["", "abc", "0", "0m", "25h", "24h1m", "1h60", "1:60", "1:5", "-5", "1.5h", "h", "99999999999999999h"])
    func rejectsText(_ text: String) {
        #expect(CustomDurationView.duration(from: text) == nil)
    }

    // MARK: - The line below the field

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    private let locale = Locale(identifier: "en_GB")

    @Test func showsWhenTheSessionWouldEnd() throws {
        let now = try Date("2026-09-24T14:00:00Z", strategy: .iso8601)

        #expect(CustomDurationView.summary(for: "1h30", now: now, calendar: calendar, locale: locale) == "Until 15:30")
    }

    @Test func namesTheDayWhenTheSessionWouldEndTomorrow() throws {
        let thursdayMorning = try Date("2026-09-24T10:00:00Z", strategy: .iso8601)

        #expect(CustomDurationView.summary(for: "24h", now: thursdayMorning, calendar: calendar, locale: locale) == "Until Fri 10:00")
    }

    @Test func hintsWhenTheTextIsNotADuration() {
        #expect(CustomDurationView.summary(for: "abc", now: .now, calendar: calendar, locale: locale) == "Try 45m or 1h30")
    }
}
