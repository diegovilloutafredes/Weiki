import AppKit

/// Tells when a running app quits; replaceable so tests never depend on real apps.
protocol AppQuitWatcher {
    /// Calls `onQuit` once `app` quits, however it quits, or before returning if `app` isn't
    /// running. Watching an app replaces the previous watch. A report can still arrive after
    /// `stopWatching()` or a newer watch, so the caller checks what it's waiting for.
    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void)
    /// Stops the current watch, if any.
    func stopWatching()
}

/// Watches a real app through `NSRunningApplication.isTerminated`, which changes however the
/// app ends, including a crash or a force quit.
final class SystemAppQuitWatcher: AppQuitWatcher {
    // Stored properties are released in declaration order, so the observation goes before the
    // app it observes: releasing an object while it's still observed is a crash.
    private var observation: NSKeyValueObservation?
    /// Kept alive for as long as it's observed, because KVO doesn't retain it.
    private var runningApp: NSRunningApplication?

    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void) {
        stopWatching()
        guard let runningApp = NSRunningApplication(processIdentifier: app.processIdentifier),
              !runningApp.isTerminated else { return onQuit() }
        self.runningApp = runningApp
        // KVO may call back on any thread. `.initial` covers an app that quits between the check
        // above and the observation starting.
        observation = runningApp.observe(\.isTerminated, options: [.initial, .new]) { @Sendable runningApp, _ in
            guard runningApp.isTerminated else { return }
            Task { @MainActor in onQuit() }
        }
    }

    func stopWatching() {
        observation?.invalidate()
        observation = nil
        runningApp = nil
    }
}
