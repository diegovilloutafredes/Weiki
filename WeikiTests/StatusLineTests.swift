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
    private let xcode = WatchedApp(processIdentifier: 42, name: "Xcode")

    private func statusLine(_ state: AwakeController.State, locale: String = "en_GB") -> String {
        state.statusLine(now: now, calendar: calendar, locale: Locale(identifier: locale))
    }

    @Test func noSession() {
        #expect(statusLine(.off) == "Weiki is off")
    }

    @Test func indefiniteSession() {
        #expect(statusLine(.on(until: .never, paused: false)) == "Awake indefinitely")
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

        #expect(statusLine(.on(until: .date(endDate), paused: false), locale: localeIdentifier) == expected)
    }

    @Test func sessionUntilAnAppQuits() {
        #expect(statusLine(.on(until: .appQuits(xcode), paused: false)) == "Awake until Xcode quits")
    }

    @Test func pausedIndefiniteSession() {
        #expect(statusLine(.on(until: .never, paused: true)) == "Paused on battery")
    }

    @Test func pausedTimedSession() throws {
        let today = try Date("2026-09-24T14:35:00Z", strategy: .iso8601)
        let tomorrow = try Date("2026-09-25T09:10:00Z", strategy: .iso8601)

        #expect(statusLine(.on(until: .date(today), paused: true)) == "Paused on battery, until 14:35")
        #expect(statusLine(.on(until: .date(tomorrow), paused: true)) == "Paused on battery, until Fri 09:10")
    }

    @Test func pausedSessionUntilAnAppQuits() {
        #expect(statusLine(.on(until: .appQuits(xcode), paused: true)) == "Paused on battery, until Xcode quits")
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

    // MARK: - Menu bar text

    @Test func menuBarTextFollowsTheKindOfSession() throws {
        let end = try Date("2026-09-24T14:35:00Z", strategy: .iso8601)
        let locale = Locale(identifier: "en_US")

        #expect(AwakeController.State.off.menuBarText(minutesLeft: nil, locale: locale) == nil)
        #expect(AwakeController.State.on(until: .never, paused: false).menuBarText(minutesLeft: nil, locale: locale) == "∞")
        #expect(AwakeController.State.on(until: .date(end), paused: false).menuBarText(minutesLeft: 42, locale: locale) == "42m")
        #expect(AwakeController.State.on(until: .appQuits(xcode), paused: false).menuBarText(minutesLeft: nil, locale: locale) == "Xcode")
    }

    /// A paused session keeps its text; only the cup changes.
    @Test func pausedSessionKeepsItsMenuBarText() {
        let locale = Locale(identifier: "en_US")

        #expect(AwakeController.State.on(until: .never, paused: true).menuBarText(minutesLeft: nil, locale: locale) == "∞")
        #expect(AwakeController.State.on(until: .appQuits(xcode), paused: true).menuBarText(minutesLeft: nil, locale: locale) == "Xcode")
    }

    @Test(arguments: [
        ("Xcode", "Xcode"),
        ("TextEditor", "TextEditor"),
        ("Visual Studio Code", "Visual Stu…"),
        // A cut that ends in a space drops the space.
        ("Microsoft Word", "Microsoft…"),
    ])
    func appNamesAreCutToTenCharacters(name: String, expected: String) {
        let state = AwakeController.State.on(until: .appQuits(WatchedApp(processIdentifier: 7, name: name)), paused: false)

        #expect(state.menuBarText(minutesLeft: nil, locale: Locale(identifier: "en_US")) == expected)
    }
}
