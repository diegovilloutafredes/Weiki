import Foundation

/// Polls `condition` until it holds or `timeout` passes; returns whether it held.
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now >= deadline { return false }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return true
}
