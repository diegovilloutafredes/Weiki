import AppKit

/// Tells when a running app quits; replaceable so tests never depend on real apps.
protocol AppQuitWatcher {
    /// Calls `onQuit` once `app` quits, however it quits, or soon after this call if it
    /// already has. Watching an app replaces the previous watch.
    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void)
    /// Stops the current watch, if any.
    func stopWatching()
}

/// Watches a real app through `NSRunningApplication.isTerminated`, which changes however the
/// app ends, including a crash or a force quit.
final class SystemAppQuitWatcher: AppQuitWatcher {
    /// Kept alive for as long as it's observed: KVO doesn't retain the observed object, and
    /// letting it go while observed is a crash.
    private var runningApp: NSRunningApplication?
    private var observation: NSKeyValueObservation?

    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void) {
        stopWatching()
        guard let runningApp = NSRunningApplication(processIdentifier: app.processIdentifier) else {
            Task { onQuit() }
            return
        }
        self.runningApp = runningApp
        // KVO may call back on any thread. `.initial` covers an app that quit just before the
        // watch began.
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
