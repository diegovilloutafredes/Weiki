import Foundation
import Testing
@testable import Weiki

/// Which other processes the menu lists as keeping the Mac awake.
struct SleepBlockersTests {
    private let weiki: pid_t = 40
    /// Dock names, for the processes that are apps.
    private let appNames: [pid_t: String] = [21: "Xcode", 22: "iTerm2"]

    private func list(_ assertions: [pid_t: ProcessAssertions]) -> [SleepBlocker] {
        SleepBlockers.list(from: assertions, appName: { appNames[$0] }, excluding: weiki)
    }

    private func process(_ name: String?, keepsDisplayOn: Bool = false) -> ProcessAssertions {
        ProcessAssertions(processName: name, keepsDisplayOn: keepsDisplayOn)
    }

    @Test func listsEachProcessWithWhatItKeepsAwake() {
        #expect(list([10: process("caffeinate"), 20: process("zoom.us", keepsDisplayOn: true)]) == [
            SleepBlocker(name: "caffeinate", keepsDisplayOn: false),
            SleepBlocker(name: "zoom.us", keepsDisplayOn: true),
        ])
    }

    @Test func leavesOutWeikiAndThePowerManager() {
        #expect(list([30: process("powerd"), weiki: process("Weiki", keepsDisplayOn: true)]).isEmpty)
    }

    @Test func processesWithOneNameShareAnItem() {
        #expect(list([10: process("caffeinate"), 11: process("caffeinate", keepsDisplayOn: true)]) == [
            SleepBlocker(name: "caffeinate", keepsDisplayOn: true),
        ])
    }

    /// An app goes by its Dock name rather than its executable's.
    @Test func anAppGoesByItsDockName() {
        #expect(list([21: process("Xcode-beta")]).map(\.name) == ["Xcode"])
    }

    @Test func leavesOutProcessesWithoutNames() {
        #expect(list([99: process(nil, keepsDisplayOn: true)]).isEmpty)
    }

    /// Sorted the way Finder sorts names, so "iTerm2" comes before "Xcode" and "zoom.us".
    @Test func sortsLikeFinder() {
        let assertions: [pid_t: ProcessAssertions] = [
            20: process("zoom.us", keepsDisplayOn: true),
            21: process("Xcode"),
            22: process("iTerm2"),
        ]

        #expect(list(assertions).map(\.name) == ["iTerm2", "Xcode", "zoom.us"])
    }

    // MARK: - Assertion types

    @Test(arguments: [
        ("PreventUserIdleDisplaySleep", AssertionEffect.keepsDisplayOn),
        ("NoDisplaySleepAssertion", .keepsDisplayOn),
        ("PreventUserIdleSystemSleep", .keepsMacAwake),
        ("NoIdleSleepAssertion", .keepsMacAwake),
        ("PreventSystemSleep", .keepsMacAwake),
        ("NetworkClientActive", .keepsMacAwake),
    ])
    func typesThatKeepTheMacAwake(type: String, effect: AssertionEffect) {
        #expect(SystemPowerAssertions.effect(ofType: type) == effect)
    }

    /// macOS's own bookkeeping, and assertions that don't keep the Mac awake.
    @Test(arguments: [
        "InternalPreventDisplaySleep",
        "InternalPreventSleep",
        "UserIsActive",
        "BackgroundTask",
        "ApplePushServiceTask",
        "PreventDiskIdle",
    ])
    func typesThatDont(type: String) {
        #expect(SystemPowerAssertions.effect(ofType: type) == nil)
    }
}
