import AppKit

/// Calls `refresh` each time one of the app's menus starts opening, early enough that the menu
/// that's opening shows what it sets. For objects that live as long as the app: the observer
/// is never removed.
func refreshWhenAMenuOpens(_ refresh: @escaping @MainActor () -> Void) {
    _ = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main) { _ in
        MainActor.assumeIsolated { refresh() }
    }
}
