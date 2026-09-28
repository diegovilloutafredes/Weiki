import AppKit
import Testing
@testable import Weiki

/// The real watcher, against processes that are or aren't running — without launching an app.
struct SystemAppQuitWatcherTests {
    /// Set by a watcher's `onQuit`.
    private final class QuitFlag {
        var isSet = false
    }

    /// `watch` refuses an app that isn't running, so a session never starts for it.
    @Test func anAppThatIsNotRunningIsRefused() {
        let watcher = SystemAppQuitWatcher()
        let quit = QuitFlag()

        let watching = watcher.watch(WatchedApp(processIdentifier: -1, name: "Gone")) { quit.isSet = true }

        #expect(watching == false)
        #expect(quit.isSet == false)
    }

    /// Weiki itself hosts the tests, so it is running: watching it never reports a quit.
    @Test func aRunningAppIsNotReportedAsQuit() async throws {
        let watcher = SystemAppQuitWatcher()
        let quit = QuitFlag()
        let weiki = WatchedApp(processIdentifier: NSRunningApplication.current.processIdentifier, name: "Weiki")

        let watching = watcher.watch(weiki) { quit.isSet = true }
        try await Task.sleep(for: .milliseconds(200))

        #expect(watching)
        #expect(quit.isSet == false)
        watcher.stopWatching()
    }
}
