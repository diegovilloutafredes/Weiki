import AppKit

/// Tells when a running app quits; replaceable so tests never depend on real apps.
protocol AppQuitWatcher {
    /// Starts watching `app`, replacing the previous watch, and calls `onQuit` once it quits,
    /// however it quits. Returns false, without watching, when `app` isn't running. A report can
    /// still arrive after `stopWatching()` or a newer watch, so the caller checks what it's
    /// waiting for.
    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void) -> Bool
    /// Stops the current watch, if any.
    func stopWatching()
}

/// Watches a real app through `NSRunningApplication.isTerminated`, which changes however the
/// app ends, including a crash or a force quit.
final class SystemAppQuitWatcher: AppQuitWatcher {
    private var observedApp: ObservedApp?

    func watch(_ app: WatchedApp, onQuit: @escaping @MainActor () -> Void) -> Bool {
        stopWatching()
        guard let runningApp = NSRunningApplication(processIdentifier: app.processIdentifier),
              !runningApp.isTerminated else { return false }
        observedApp = ObservedApp(runningApp, onQuit: onQuit)
        return true
    }

    func stopWatching() {
        observedApp = nil
    }
}

/// One app under KVO observation. It keeps the app alive while observing it, because KVO
/// doesn't retain the observed object, and releasing an observed object is a crash. `deinit`
/// ends the observation before the app is released.
private nonisolated final class ObservedApp {
    private let runningApp: NSRunningApplication
    private let observation: NSKeyValueObservation

    init(_ runningApp: NSRunningApplication, onQuit: @escaping @MainActor () -> Void) {
        self.runningApp = runningApp
        // KVO may call back on any thread. `.initial` covers an app that quits between the
        // running check and the observation starting.
        observation = runningApp.observe(\.isTerminated, options: [.initial, .new]) { @Sendable runningApp, _ in
            guard runningApp.isTerminated else { return }
            Task { @MainActor in onQuit() }
        }
    }

    deinit {
        observation.invalidate()
    }
}
