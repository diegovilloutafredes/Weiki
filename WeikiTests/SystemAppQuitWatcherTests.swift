import AppKit
import Testing
@testable import Weiki

/// The real watcher, against processes that are or aren't running — without launching an app.
struct SystemAppQuitWatcherTests {
    /// Set by a watcher's `onQuit`.
    private final class QuitFlag {
        var isSet = false
    }

    /// Reported before `watch` returns, so a session never starts for an app that's gone.
    @Test func anAppThatIsNotRunningIsReportedAtOnce() {
        let watcher = SystemAppQuitWatcher()
        let quit = QuitFlag()

        watcher.watch(WatchedApp(processIdentifier: -1, name: "Gone")) { quit.isSet = true }

        #expect(quit.isSet)
    }

    /// Weiki itself hosts the tests, so it is running: watching it never reports a quit.
    @Test func aRunningAppIsNotReportedAsQuit() async throws {
        let watcher = SystemAppQuitWatcher()
        let quit = QuitFlag()
        let weiki = WatchedApp(processIdentifier: NSRunningApplication.current.processIdentifier, name: "Weiki")

        watcher.watch(weiki) { quit.isSet = true }
        try await Task.sleep(for: .milliseconds(200))

        #expect(quit.isSet == false)
        watcher.stopWatching()
    }
}
