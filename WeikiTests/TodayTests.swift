import Foundation
import Testing
@testable import Weiki

struct TodayTests {
    /// Anything that changes how an end time reads — the day, the time zone, the
    /// locale's clock — must re-render the status line.
    @Test(arguments: [
        Notification.Name.NSCalendarDayChanged,
        .NSSystemTimeZoneDidChange,
        NSLocale.currentLocaleDidChangeNotification,
    ])
    func movesForwardWhen(_ change: Notification.Name) async throws {
        let today = Today()
        let before = today.date
        try await Task.sleep(for: .milliseconds(20))

        NotificationCenter.default.post(name: change, object: nil)

        let moved = await waitUntil { today.date > before }
        #expect(moved)
    }
}
