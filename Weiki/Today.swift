import Foundation
import Observation

/// The current day, for text that depends on it ("Awake until Fri 09:10").
///
/// A `.menu`-style `MenuBarExtra` only re-renders when observed state changes — not when
/// the menu opens, and not for a `TimelineView` — so views read `date` instead of `.now`.
/// It moves forward whenever something changes how an end time reads: the calendar day
/// (macOS also posts that on wake), the time zone, or the locale's clock.
@Observable
final class Today {
    private(set) var date = Date.now

    init() {
        let changes: [Notification.Name] = [
            .NSCalendarDayChanged,
            .NSSystemTimeZoneDidChange,
            NSLocale.currentLocaleDidChangeNotification,
        ]
        // Lives as long as the app, so the observers are never removed.
        for change in changes {
            _ = NotificationCenter.default.addObserver(forName: change, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.date = .now }
            }
        }
    }
}
