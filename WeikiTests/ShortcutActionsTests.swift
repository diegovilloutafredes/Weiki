import Foundation
import Testing
@testable import Weiki

/// What the Shortcuts actions start, apart from the App Intents glue.
struct ShortcutActionsTests {
    @Test func noDurationKeepsTheMacAwakeIndefinitely() throws {
        #expect(try ShortcutActions.option(forSeconds: nil) == .indefinitely)
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
        #expect(try ShortcutActions.option(forSeconds: seconds) == option)
    }

    @Test(arguments: [0.0, 59, 86_401, -60])
    func durationsOutsideOneMinuteToADayAreRefused(seconds: TimeInterval) {
        #expect(throws: ShortcutError.durationOutOfRange) {
            try ShortcutActions.option(forSeconds: seconds)
        }
    }

    @Test func aRunningAppIsFoundByItsBundleIdentifier() throws {
        let keynote = WatchedApp(processIdentifier: 502, name: "Keynote", bundleIdentifier: "com.apple.iWork.Keynote")
        let safari = WatchedApp(processIdentifier: 503, name: "Safari", bundleIdentifier: "com.apple.Safari")

        let option = try ShortcutActions.option(untilQuit: "com.apple.iWork.Keynote", named: "Keynote", among: [safari, keynote])

        #expect(option == .untilQuit(keynote))
    }

    @Test func anAppThatIsntRunningIsRefusedByName() {
        let safari = WatchedApp(processIdentifier: 503, name: "Safari", bundleIdentifier: "com.apple.Safari")

        #expect(throws: ShortcutError.appNotRunning("Keynote")) {
            try ShortcutActions.option(untilQuit: "com.apple.iWork.Keynote", named: "Keynote", among: [safari])
        }
    }

    /// Shortcuts shows these messages when an action fails.
    @Test func errorMessagesSayWhatToDo() {
        let tooLong = String(localized: ShortcutError.durationOutOfRange.localizedStringResource)
        let notRunning = String(localized: ShortcutError.appNotRunning("Keynote").localizedStringResource)

        #expect(tooLong.contains("1 minute") && tooLong.contains("24 hours"))
        #expect(notRunning.contains("Keynote"))
    }
}
