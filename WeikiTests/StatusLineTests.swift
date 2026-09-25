import Foundation
import Testing
@testable import Weiki

struct StatusLineTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    /// A Thursday.
    private let now = try! Date("2026-09-24T10:00:00Z", strategy: .iso8601)

    @Test func noSession() {
        let line = AwakeController.State.off.statusLine(now: now, calendar: calendar, locale: Locale(identifier: "en_GB"))

        #expect(line == "Weiki is off")
    }

    @Test func indefiniteSession() {
        let line = AwakeController.State.on(until: nil).statusLine(now: now, calendar: calendar, locale: Locale(identifier: "en_GB"))

        #expect(line == "Awake indefinitely")
    }

    @Test(arguments: [
        // Ends today: the time alone, in the locale's clock.
        ("en_GB", "2026-09-24T14:35:00Z", "Awake until 14:35"),
        ("en_US", "2026-09-24T14:35:00Z", "Awake until 2:35\u{202F}PM"),
        // Ends another day: the abbreviated weekday is added.
        ("en_GB", "2026-09-25T09:10:00Z", "Awake until Fri 09:10"),
        ("en_US", "2026-09-25T00:30:00Z", "Awake until Fri 12:30\u{202F}AM"),
    ])
    func timedSession(localeIdentifier: String, end: String, expected: String) throws {
        let endDate = try Date(end, strategy: .iso8601)

        let line = AwakeController.State.on(until: endDate)
            .statusLine(now: now, calendar: calendar, locale: Locale(identifier: localeIdentifier))

        #expect(line == expected)
    }

    /// The menu bar's countdown text, in whole minutes.
    @Test(arguments: [
        (1, "1m"),
        (42, "42m"),
        (60, "1h"),
        (65, "1h 5m"),
        (1495, "24h 55m"),
    ])
    func timeLeft(minutes: Int, expected: String) {
        #expect(timeLeftText(minutes: minutes, locale: Locale(identifier: "en_US")) == expected)
    }
}
