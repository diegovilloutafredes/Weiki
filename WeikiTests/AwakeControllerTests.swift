import Foundation
import Testing
@testable import Weiki

/// The controller's "now", moved forward by hand. A reference type so it outlives
/// each test: a session's end loop can still read it after the test returns.
final class TestClock {
    var now = Date(timeIntervalSinceReferenceDate: 780_000_000)
}

@Suite final class AwakeControllerTests {
    private let suiteName = "WeikiTests-\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let service = RecordingPowerAssertions()
    private let clock = TestClock()
    private let appWatcher = FakeAppQuitWatcher()
    private let power = FakePowerSource()
    private let xcode = WatchedApp(processIdentifier: 501, name: "Xcode")
    private let keynote = WatchedApp(processIdentifier: 502, name: "Keynote")

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    private func makeController() -> AwakeController {
        AwakeController(
            service: service,
            defaults: defaults,
            now: { [clock] in clock.now },
            appWatcher: appWatcher,
            powerSource: power
        )
    }

    // MARK: - Starting and stopping

    @Test func launchesWithNoSession() {
        let controller = makeController()

        #expect(controller.state == .off)
        #expect(service.calls.isEmpty)
    }

    @Test func indefiniteSessionHoldsWithoutTimeout() {
        let controller = makeController()

        controller.start(.indefinitely)

        #expect(controller.state == .on(until: .never, paused: false))
        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 0)])
        #expect(service.details == ["Display kept on, indefinitely"])
    }

    @Test func timedSessionEndsAfterItsDuration() {
        let controller = makeController()
        let start = clock.now

        controller.start(.custom(3600))

        #expect(controller.state == .on(until: .date(start.addingTimeInterval(3600)), paused: false))
        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 3600)])
        #expect(service.details.first?.hasPrefix("Display kept on, until ") == true)
    }

    @Test func subSecondRemainderStillCarriesATimeout() {
        let controller = makeController()

        controller.start(.custom(0.4))

        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 1)])
    }

    @Test func startingDuringASessionAcquiresTheNewHoldBeforeReleasingTheOld() {
        let controller = makeController()
        controller.start(.indefinitely)
        clock.now += 60

        controller.start(.custom(900))

        #expect(controller.state == .on(until: .date(clock.now.addingTimeInterval(900)), paused: false))
        #expect(service.calls == [
            .acquire(keepsDisplayOn: true, timeout: 0),
            .acquire(keepsDisplayOn: true, timeout: 900),
            .release(1),
        ])
        #expect(service.heldIDs == [2])
    }

    @Test func turningOffReleasesTheHold() {
        let controller = makeController()
        controller.start(.custom(900))

        controller.stop()

        #expect(controller.state == .off)
        #expect(service.calls.last == .release(1))
        #expect(service.heldIDs.isEmpty)
    }

    // MARK: - Display mode

    @Test func keepDisplayOnDefaultsToOnAndPersists() {
        let first = makeController()
        #expect(first.keepsDisplayOn)

        first.keepsDisplayOn = false

        #expect(makeController().keepsDisplayOn == false)
    }

    @Test func modeChangeDuringASessionKeepsTheEndTimeAndHoldsForTheRemainingTime() {
        let controller = makeController()
        let start = clock.now
        controller.start(.custom(3600))
        clock.now += 600

        controller.keepsDisplayOn = false

        #expect(controller.state == .on(until: .date(start.addingTimeInterval(3600)), paused: false))
        #expect(service.calls == [
            .acquire(keepsDisplayOn: true, timeout: 3600),
            .acquire(keepsDisplayOn: false, timeout: 3000),
            .release(1),
        ])
        #expect(service.details.last?.hasPrefix("Display allowed to sleep, until ") == true)
    }

    @Test func settingTheSameModeAgainChangesNothing() {
        let controller = makeController()
        controller.start(.custom(3600))

        controller.keepsDisplayOn = true

        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 3600)])
    }

    @Test func modeChangeWithNoSessionMakesNoHold() {
        let controller = makeController()

        controller.keepsDisplayOn = false

        #expect(controller.state == .off)
        #expect(service.calls.isEmpty)
    }

    @Test func modeChangeAfterTheEndTimeTurnsOffInsteadOfHoldingAgain() {
        let controller = makeController()
        controller.start(.custom(60))
        clock.now += 120

        controller.keepsDisplayOn = false

        #expect(controller.state == .off)
        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 60), .release(1)])
    }

    // MARK: - Refused holds

    @Test func refusedHoldLeavesNoSession() {
        let controller = makeController()
        service.refusesHolds = true

        controller.start(.indefinitely)

        #expect(controller.state == .off)
        #expect(service.heldIDs.isEmpty)
    }

    @Test func refusedReplacementReleasesThePreviousHoldAndTurnsOff() throws {
        let controller = makeController()
        controller.start(.indefinitely)
        try #require(service.heldIDs == [1])
        service.refusesHolds = true

        controller.start(.custom(900))

        #expect(controller.state == .off)
        #expect(service.heldIDs.isEmpty)
    }

    @Test func refusedHoldOnModeChangeReleasesThePreviousHoldAndTurnsOff() throws {
        let controller = makeController()
        controller.start(.indefinitely)
        try #require(service.heldIDs == [1])
        service.refusesHolds = true

        controller.keepsDisplayOn = false

        #expect(controller.state == .off)
        #expect(service.heldIDs.isEmpty)
    }

    // MARK: - Hold details

    @Test func holdDetailsNameTheDayWhenTheSessionEndsOnAnotherDay() throws {
        let controller = makeController()
        let end = clock.now.addingTimeInterval(86_400 + 60)
        let weekday = end.formatted(.dateTime.weekday(.abbreviated))

        controller.start(.custom(86_400 + 60))

        let details = try #require(service.details.first)
        #expect(details.contains(weekday))
    }

    // MARK: - Timed end

    @Test func timedSessionEndsOnItsOwn() async throws {
        let controller = AwakeController(service: service, defaults: defaults)

        controller.start(.custom(0.2))
        try #require(controller.state != .off)
        try #require(controller.activeOption == .custom(0.2))

        let ended = await waitUntil { controller.state == .off }
        #expect(ended)
        #expect(service.heldIDs.isEmpty)
        #expect(controller.activeOption == nil)
    }

    @Test func replacingATimedSessionCancelsItsEnd() async throws {
        let controller = AwakeController(service: service, defaults: defaults)
        controller.start(.custom(0.1))

        controller.start(.indefinitely)
        try await Task.sleep(for: .milliseconds(400))

        #expect(controller.state == .on(until: .never, paused: false))
        #expect(service.heldIDs == [2])
    }

    @Test func modeChangeKeepsTheSessionRunningUntilItsEnd() async throws {
        let controller = AwakeController(service: service, defaults: defaults)
        controller.start(.custom(0.5))

        controller.keepsDisplayOn = false
        try await Task.sleep(for: .milliseconds(100))

        #expect(controller.state != .off)
        let ended = await waitUntil { controller.state == .off }
        #expect(ended)
    }

    /// A Mac that slept past the end: the loop never waits more than a minute at a time,
    /// and re-reads the clock, so a jump past the end turns the session off on the next tick.
    @Test func endLoopSleepsAtMostAMinuteAndRereadsTheClock() async throws {
        let probe = LoopProbe()
        let controller = AwakeController(
            service: service,
            defaults: defaults,
            now: { [clock] in clock.now },
            sleep: { [probe] duration in
                probe.sleeps.append(duration)
                try await Task.sleep(for: .milliseconds(10))
            }
        )
        controller.start(.custom(3600))
        try #require(await waitUntil { probe.sleeps.count >= 2 })
        #expect(probe.sleeps.allSatisfy { $0 == .seconds(60) })

        clock.now += 3601

        let ended = await waitUntil { controller.state == .off }
        #expect(ended)
        #expect(service.heldIDs.isEmpty)
    }

    // MARK: - Active option

    @Test func startingAnOptionMakesItActive() {
        let controller = makeController()

        controller.start(.indefinitely)

        #expect(controller.activeOption == .indefinitely)
    }

    @Test func startingAnotherOptionReplacesTheActiveOne() {
        let controller = makeController()
        controller.start(.indefinitely)

        controller.start(.oneHour)

        #expect(controller.activeOption == .oneHour)
    }

    @Test func turningOffClearsTheActiveOption() throws {
        let controller = makeController()
        controller.start(.oneHour)
        try #require(controller.activeOption == .oneHour)

        controller.stop()

        #expect(controller.activeOption == nil)
        #expect(controller.minutesLeft == nil)
    }

    @Test func refusedHoldClearsTheActiveOption() throws {
        let controller = makeController()
        controller.start(.indefinitely)
        try #require(controller.activeOption == .indefinitely)
        service.refusesHolds = true

        controller.start(.oneHour)

        #expect(controller.activeOption == nil)
    }

    @Test func modeChangeKeepsTheActiveOption() {
        let controller = makeController()
        controller.start(.oneHour)

        controller.keepsDisplayOn = false

        #expect(controller.activeOption == .oneHour)
    }

    // MARK: - Minutes left

    @Test func minutesLeftIsRoundedUpWhenASessionStarts() {
        let controller = makeController()

        controller.start(.custom(41 * 60 + 10))

        #expect(controller.minutesLeft == 42)
    }

    @Test func minutesLeftIsNilWithoutATimedSession() {
        let controller = makeController()
        #expect(controller.minutesLeft == nil)

        controller.start(.indefinitely)

        #expect(controller.minutesLeft == nil)
    }

    /// The loop wakes exactly when the shown minute changes: 2 min 30 s shows 3, then
    /// after 30 s shows 2, after another 60 s shows 1, and 60 s later the session ends.
    @Test func minutesLeftCountsDownAtEachMinute() async throws {
        let probe = LoopProbe()
        let controller = AwakeController(
            service: service,
            defaults: defaults,
            now: { [clock] in clock.now },
            sleep: { [clock, probe] duration in
                probe.sleeps.append(duration)
                probe.minutesLeftAtEachSleep.append(probe.controller?.minutesLeft)
                let (seconds, attoseconds) = duration.components
                clock.now += Double(seconds) + Double(attoseconds) / 1e18
            }
        )
        probe.controller = controller

        controller.start(.custom(150))

        let ended = await waitUntil { controller.state == .off }
        #expect(ended)
        #expect(probe.sleeps == [.seconds(30), .seconds(60), .seconds(60)])
        #expect(probe.minutesLeftAtEachSleep == [3, 2, 1])
        #expect(controller.minutesLeft == nil)
    }

    // MARK: - Until an app quits

    @Test func choosingAnAppHoldsWithoutTimeoutUntilItQuits() {
        let controller = makeController()

        controller.start(.untilQuit(xcode))

        #expect(controller.state == .on(until: .appQuits(xcode), paused: false))
        #expect(controller.activeOption == .untilQuit(xcode))
        #expect(controller.minutesLeft == nil)
        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 0)])
        #expect(service.details == ["Display kept on, until Xcode quits"])
        #expect(appWatcher.watched == xcode)
    }

    @Test func theAppQuittingTurnsTheSessionOff() {
        let controller = makeController()
        controller.start(.untilQuit(xcode))

        appWatcher.quitWatchedApp()

        #expect(controller.state == .off)
        #expect(controller.activeOption == nil)
        #expect(service.heldIDs.isEmpty)
        #expect(appWatcher.watched == nil)
    }

    @Test func anAppThatHasAlreadyQuitStartsNoSession() {
        let controller = makeController()
        appWatcher.quitApps = [xcode]

        controller.start(.untilQuit(xcode))

        #expect(controller.state == .off)
        #expect(controller.activeOption == nil)
        #expect(service.heldIDs.isEmpty)
    }

    @Test func choosingAnotherAppWatchesItInstead() {
        let controller = makeController()
        controller.start(.untilQuit(xcode))

        controller.start(.untilQuit(keynote))

        #expect(controller.state == .on(until: .appQuits(keynote), paused: false))
        #expect(appWatcher.watched == keynote)
        #expect(service.heldIDs == [2])
    }

    @Test func replacingTheSessionStopsTheWatch() {
        let controller = makeController()
        controller.start(.untilQuit(xcode))

        controller.start(.oneHour)

        #expect(appWatcher.watched == nil)
    }

    @Test func turningOffStopsTheWatch() {
        let controller = makeController()
        controller.start(.untilQuit(xcode))

        controller.stop()

        #expect(appWatcher.watched == nil)
    }

    /// The system may deliver the quit after the session moved on; it must not end the new one.
    @Test func aLateQuitForAReplacedAppChangesNothing() throws {
        let controller = makeController()
        controller.start(.untilQuit(xcode))
        let lateOnQuit = try #require(appWatcher.latestOnQuit)
        controller.start(.oneHour)
        let oneHourSession = controller.state

        lateOnQuit()

        #expect(controller.state == oneHourSession)
        #expect(controller.activeOption == .oneHour)
        #expect(service.heldIDs == [2])
    }

    @Test func modeChangeKeepsWaitingForTheApp() {
        let controller = makeController()
        controller.start(.untilQuit(xcode))

        controller.keepsDisplayOn = false

        #expect(controller.state == .on(until: .appQuits(xcode), paused: false))
        #expect(service.details.last == "Display allowed to sleep, until Xcode quits")
        #expect(appWatcher.watched == xcode)
    }

    // MARK: - Only on AC Power

    @Test func onlyOnACPowerDefaultsToOffAndPersists() {
        let first = makeController()
        #expect(first.onlyOnACPower == false)

        first.onlyOnACPower = true

        #expect(makeController().onlyOnACPower)
    }

    @Test func unpluggingPausesTheSessionAndKeepsItsEnd() {
        let controller = makeController()
        controller.onlyOnACPower = true
        let end = clock.now.addingTimeInterval(3600)
        controller.start(.custom(3600))

        power.isOnACPower = false

        #expect(controller.state == .on(until: .date(end), paused: true))
        #expect(controller.state.isHolding == false)
        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 3600), .release(1)])
        #expect(controller.activeOption == .custom(3600))
        #expect(controller.minutesLeft == 60)
    }

    @Test func startingOnBatteryStartsPaused() {
        let controller = makeController()
        controller.onlyOnACPower = true
        power.isOnACPower = false

        controller.start(.oneHour)

        #expect(controller.state == .on(until: .date(clock.now.addingTimeInterval(3600)), paused: true))
        #expect(controller.activeOption == .oneHour)
        #expect(service.calls.isEmpty)
    }

    @Test func turningTheSettingOnWhileOnBatteryPauses() {
        let controller = makeController()
        power.isOnACPower = false
        controller.start(.indefinitely)

        controller.onlyOnACPower = true

        #expect(controller.state == .on(until: .never, paused: true))
        #expect(service.heldIDs.isEmpty)
    }

    @Test func turningTheSettingOffWhilePausedResumes() {
        let controller = makeController()
        controller.onlyOnACPower = true
        power.isOnACPower = false
        controller.start(.indefinitely)

        controller.onlyOnACPower = false

        #expect(controller.state == .on(until: .never, paused: false))
        #expect(controller.state.isHolding)
        #expect(service.heldIDs == [1])
    }

    @Test func pluggingInResumesWithTheRemainingTime() {
        let controller = makeController()
        controller.onlyOnACPower = true
        let end = clock.now.addingTimeInterval(3600)
        controller.start(.custom(3600))
        power.isOnACPower = false
        clock.now += 1800

        power.isOnACPower = true

        #expect(controller.state == .on(until: .date(end), paused: false))
        #expect(service.calls == [
            .acquire(keepsDisplayOn: true, timeout: 3600),
            .release(1),
            .acquire(keepsDisplayOn: true, timeout: 1800),
        ])
        #expect(service.heldIDs == [2])
        #expect(controller.minutesLeft == 30)
    }

    @Test func modeChangeWhilePausedHoldsNothingAndResumesInTheNewMode() {
        let controller = makeController()
        controller.onlyOnACPower = true
        power.isOnACPower = false
        controller.start(.indefinitely)

        controller.keepsDisplayOn = false

        #expect(service.calls.isEmpty)
        power.isOnACPower = true
        #expect(service.calls == [.acquire(keepsDisplayOn: false, timeout: 0)])
    }

    @Test func refusedHoldOnResumeTurnsOff() {
        let controller = makeController()
        controller.onlyOnACPower = true
        power.isOnACPower = false
        controller.start(.indefinitely)
        service.refusesHolds = true

        power.isOnACPower = true

        #expect(controller.state == .off)
        #expect(controller.activeOption == nil)
        #expect(service.heldIDs.isEmpty)
    }

    /// Reports that don't change whether the session must pause leave its hold alone.
    @Test func reportsThatDontChangeThePauseLeaveTheHoldAlone() {
        let controller = makeController()
        controller.start(.indefinitely)

        power.isOnACPower = false // The setting is off, so the session keeps holding.
        power.isOnACPower = true
        controller.onlyOnACPower = true // On AC power there's nothing to pause.
        power.isOnACPower = true // Still on AC power, as reported on wake.

        #expect(service.calls == [.acquire(keepsDisplayOn: true, timeout: 0)])
        #expect(controller.state == .on(until: .never, paused: false))
    }

    @Test func aSessionUntilAnAppQuitsPausesAndStillEndsWhenTheAppQuits() {
        let controller = makeController()
        controller.onlyOnACPower = true
        power.isOnACPower = false
        controller.start(.untilQuit(xcode))
        #expect(controller.state == .on(until: .appQuits(xcode), paused: true))
        #expect(appWatcher.watched == xcode)

        appWatcher.quitWatchedApp()

        #expect(controller.state == .off)
    }

    @Test func aPausedTimedSessionStillEndsOnTime() async throws {
        let controller = AwakeController(service: service, defaults: defaults, appWatcher: appWatcher, powerSource: power)
        controller.onlyOnACPower = true
        power.isOnACPower = false

        controller.start(.custom(0.2))
        try #require(controller.state != .off && !controller.state.isHolding)

        let ended = await waitUntil { controller.state == .off }
        #expect(ended)
        #expect(service.calls.isEmpty)
    }
}

/// What the end loop did: the sleeps it asked for, and the minutes left each time.
final class LoopProbe {
    weak var controller: AwakeController?
    var sleeps: [Duration] = []
    var minutesLeftAtEachSleep: [Int?] = []
}
