import Foundation
import Testing
@testable import Weiki

/// What the Shortcuts actions start, apart from the App Intents glue.
@Suite final class ShortcutActionsTests {
    private let suiteName = "WeikiTests-\(UUID().uuidString)"
    private let service = RecordingPowerAssertions()
    private let controller: AwakeController
    private let keynote = WatchedApp(processIdentifier: 502, name: "Keynote", bundleIdentifier: "com.apple.iWork.Keynote")

    init() {
        controller = AwakeController(
            service: service,
            defaults: UserDefaults(suiteName: suiteName)!,
            appWatcher: FakeAppQuitWatcher(),
            powerSource: FakePowerSource()
        )
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    // MARK: - Keep Mac Awake

    @Test func noDurationKeepsTheMacAwakeIndefinitely() throws {
        try ShortcutActions.keepAwake(forSeconds: nil, on: controller)

        #expect(controller.state == .on(until: .never, paused: false))
        #expect(controller.activeOption == .indefinitely)
    }

    /// The menu's presets are checked when a shortcut asks for their exact length.
    @Test(arguments: [
        (900.0, DurationOption.fifteenMinutes),
        (3600, .oneHour),
        (7200, .twoHours),
        (2700, .custom(2700)),
        (60, .custom(60)),
        (86_400, .custom(86_400)),
    ])
    func durationsFromOneMinuteToADay(seconds: TimeInterval, option: DurationOption) throws {
        try ShortcutActions.keepAwake(forSeconds: seconds, on: controller)

        #expect(controller.activeOption == option)
    }

    @Test func anActionReplacesTheActiveSession() throws {
        controller.start(.oneHour)

        try ShortcutActions.keepAwake(forSeconds: nil, on: controller)

        #expect(controller.activeOption == .indefinitely)
        #expect(service.heldIDs == [2])
    }

    @Test(arguments: [0.0, 59, 86_401, -60])
    func durationsOutsideOneMinuteToADayChangeNothing(seconds: TimeInterval) {
        controller.start(.oneHour)
        let session = controller.state

        #expect(throws: ShortcutError.durationOutOfRange) {
            try ShortcutActions.keepAwake(forSeconds: seconds, on: controller)
        }
        #expect(controller.state == session)
        #expect(controller.activeOption == .oneHour)
    }

    /// A shortcut must never report a session that isn't there, or an automation would carry on
    /// while the Mac sleeps.
    @Test func aRefusedHoldFailsTheAction() {
        service.refusesHolds = true

        #expect(throws: ShortcutError.couldNotStart) {
            try ShortcutActions.keepAwake(forSeconds: 3600, on: controller)
        }
        #expect(controller.state == .off)
    }

    // MARK: - Keep Mac Awake Until App Quits

    @Test func aRunningAppIsWatched() throws {
        try ShortcutActions.keepAwake(until: keynote, named: "Keynote", on: controller)

        #expect(controller.state == .on(until: .appQuits(keynote), paused: false))
    }

    @Test func anAppThatIsntRunningFailsByNameAndChangesNothing() {
        controller.start(.oneHour)
        let session = controller.state

        #expect(throws: ShortcutError.appNotRunning("Keynote")) {
            try ShortcutActions.keepAwake(until: nil, named: "Keynote", on: controller)
        }
        #expect(controller.state == session)
    }

    /// Shortcuts shows these messages when an action fails.
    @Test func errorMessagesSayWhatWentWrong() {
        let outOfRange = String(localized: ShortcutError.durationOutOfRange.localizedStringResource)
        let notRunning = String(localized: ShortcutError.appNotRunning("Keynote").localizedStringResource)

        #expect(outOfRange.contains("1 minute") && outOfRange.contains("24 hours"))
        #expect(notRunning.contains("Keynote"))
    }
}
