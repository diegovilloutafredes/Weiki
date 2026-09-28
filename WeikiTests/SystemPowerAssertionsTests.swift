import Foundation
import IOKit.pwr_mgt
import Testing
@testable import Weiki

/// This process's power assertions named `name`, read back from the system —
/// the ground truth for what `SystemPowerAssertions` actually holds.
func heldAssertions(named name: String = "Weiki") -> [[String: Any]] {
    var byProcess: Unmanaged<CFDictionary>?
    guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
          let assertions = byProcess?.takeRetainedValue() as? [NSNumber: [[String: Any]]] else { return [] }
    return (assertions[NSNumber(value: getpid())] ?? []).filter { $0["AssertName"] as? String == name }
}

/// Creates real assertions, so the tests must not overlap.
@Suite(.serialized)
struct SystemPowerAssertionsTests {
    let service = SystemPowerAssertions()

    @Test func displayModeHoldsDisplaySleepAssertion() throws {
        let id = try service.acquire(keepsDisplayOn: true, timeout: 0, details: "Display kept on, indefinitely")
        defer { service.release(id) }

        let held = heldAssertions()
        #expect(held.count == 1)
        #expect(held.first?["AssertType"] as? String == "PreventUserIdleDisplaySleep")
        #expect(held.first?["Details"] as? String == "Display kept on, indefinitely")
    }

    @Test func systemModeHoldsSystemSleepAssertion() throws {
        let id = try service.acquire(keepsDisplayOn: false, timeout: 0, details: "Display allowed to sleep, indefinitely")
        defer { service.release(id) }

        let held = heldAssertions()
        #expect(held.count == 1)
        #expect(held.first?["AssertType"] as? String == "PreventUserIdleSystemSleep")
    }

    @Test func timedHoldCarriesATimeoutThatReleasesIt() throws {
        let id = try service.acquire(keepsDisplayOn: true, timeout: 5400, details: "Display kept on, until 15:30")
        defer { service.release(id) }

        let hold = try #require(heldAssertions().first)
        #expect((hold["TimeoutSeconds"] as? NSNumber)?.doubleValue == 5400)
        #expect(hold["TimeoutAction"] as? String == "TimeoutActionRelease")
    }

    /// The safety net: the system releases a timed hold on its own, even if Weiki never does.
    @Test func systemReleasesATimedHoldWhenItsTimeoutFires() async throws {
        let id = try service.acquire(keepsDisplayOn: false, timeout: 1, details: "Display allowed to sleep, until 07:00")
        defer { service.release(id) }
        try #require(heldAssertions().count == 1)

        let released = await waitUntil(timeout: .seconds(5)) { heldAssertions().isEmpty }

        #expect(released)
    }

    @Test func indefiniteHoldHasNoTimeout() throws {
        let id = try service.acquire(keepsDisplayOn: true, timeout: 0, details: "Display kept on, indefinitely")
        defer { service.release(id) }

        let hold = try #require(heldAssertions().first)
        #expect(hold["TimeoutSeconds"] == nil)
    }

    /// The read behind "Also Keeping the Mac Awake" finds a hold under its process, with what
    /// it keeps awake and the process's name.
    @Test func assertionsByProcessFindsThisProcesssHold() throws {
        let id = try service.acquire(keepsDisplayOn: true, timeout: 0, details: "Display kept on, indefinitely")
        defer { service.release(id) }

        let own = SystemPowerAssertions.assertionsByProcess()[getpid()]
        #expect(own == ProcessAssertions(processName: ProcessInfo.processInfo.processName, effects: [.keepsDisplayOn]))
    }

    @Test func assertionsByProcessLeavesOutReleasedHolds() throws {
        let id = try service.acquire(keepsDisplayOn: false, timeout: 0, details: "Display allowed to sleep, indefinitely")
        #expect(SystemPowerAssertions.assertionsByProcess()[getpid()]?.effects == [.keepsMacAwake])

        service.release(id)

        #expect(SystemPowerAssertions.assertionsByProcess()[getpid()] == nil)
    }

    @Test func releaseRemovesTheHold() throws {
        let id = try service.acquire(keepsDisplayOn: false, timeout: 0, details: "Display allowed to sleep, indefinitely")
        #expect(heldAssertions().count == 1)

        service.release(id)

        #expect(heldAssertions().isEmpty)
    }
}
