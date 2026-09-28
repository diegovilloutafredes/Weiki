import AppKit
@testable import Weiki

/// Polls `condition` until it holds or `timeout` passes; returns whether it held.
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now >= deadline { return false }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return true
}

/// A UserDefaults suite of its own, so a test never touches Weiki's real settings. The suite
/// is deleted when this goes away, along with the test that holds it.
final class TestDefaults {
    let defaults: UserDefaults
    private let suiteName = "WeikiTests-\(UUID().uuidString)"

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }
}

/// A running app for tests, standing in for `NSRunningApplication`.
struct TestRunningApp: RunningAppInfo {
    let processIdentifier: pid_t
    let localizedName: String?
    var bundleIdentifier: String?
    var activationPolicy: NSApplication.ActivationPolicy = .regular
    var launchDate: Date?
}
