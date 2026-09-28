@testable import Weiki

/// An `AppQuitWatcher` that plays the watched app's part: tests say when it quits.
final class FakeAppQuitWatcher: AppQuitWatcher {
    /// The app being watched; nil when no watch is active.
    private(set) var watched: WatchedApp?
    /// The callback passed to the latest `watch`, kept even after `stopWatching()`, so a test
    /// can deliver it late, as the system might.
    private(set) var latestOnQuit: (@MainActor () -> Void)?
    /// Apps that have already quit: `watch` refuses them, as the real watcher does.
    var quitApps: Set<WatchedApp> = []

    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void) -> Bool {
        guard !quitApps.contains(app) else {
            watched = nil
            return false
        }
        watched = app
        latestOnQuit = onQuit
        return true
    }

    func stopWatching() {
        watched = nil
    }

    /// The watched app quits.
    func quitWatchedApp() {
        guard watched != nil else { return }
        latestOnQuit?()
    }
}
