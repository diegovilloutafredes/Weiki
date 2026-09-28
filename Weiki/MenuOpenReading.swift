import AppKit
import Observation

/// A value read from the system that is current whenever one of the app's menus opens. It's read
/// at launch and again as each menu starts opening, early enough for that menu to show it: a
/// `.menu`-style menu only re-renders when observed state changes, and nothing announces changes
/// to these values. It lives as long as the app.
@Observable
final class MenuOpenReading<Value: Equatable> {
    private(set) var value: Value
    private let read: () -> Value

    init(_ read: @escaping () -> Value) {
        self.read = read
        value = read()
        observeForever(NSMenu.didBeginTrackingNotification) { [weak self] in self?.refresh() }
    }

    /// Writes only a changed value, so an unchanged reading doesn't re-render the menu.
    private func refresh() {
        let value = read()
        if value != self.value { self.value = value }
    }
}

/// Calls `action` on the main actor for every `name` notification from `center`. For objects
/// that live as long as the app: the observer is never removed.
func observeForever(_ name: Notification.Name, in center: NotificationCenter = .default, _ action: @escaping @MainActor () -> Void) {
    _ = center.addObserver(forName: name, object: nil, queue: .main) { _ in
        MainActor.assumeIsolated { action() }
    }
}
