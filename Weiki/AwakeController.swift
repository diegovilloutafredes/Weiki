import Foundation
import Observation

/// Keep-awake sessions: the current hold, what ends it (a date, or an app quitting), and the
/// "Keep Display On" and "Only on AC Power" settings.
///
/// The end date is the source of truth for when a timed session ends. The timeout each hold
/// carries on the system side is only a safety net in case Weiki stops responding.
@Observable
final class AwakeController {
    enum State: Equatable {
        case off
        /// `paused` while "Only on AC Power" keeps the session from holding on battery.
        case on(until: SessionEnd, paused: Bool)

        /// Whether a session holds the Mac awake: on, and not paused.
        var isHolding: Bool {
            if case .on(_, paused: false) = self { true } else { false }
        }
    }

    private(set) var state: State = .off
    /// The menu option that started the active session; nil when off.
    private(set) var activeOption: DurationOption?
    /// Time left in a timed session, rounded up to whole minutes; nil when off or indefinite.
    private(set) var minutesLeft: Int?

    /// Whether sessions keep the display awake too, or only the system. Remembered across launches.
    var keepsDisplayOn: Bool {
        didSet {
            guard keepsDisplayOn != oldValue else { return }
            defaults.set(keepsDisplayOn, forKey: Self.keepsDisplayOnKey)
            if case .on(let end, _) = state { hold(until: end) }
        }
    }

    /// Whether sessions hold the Mac awake only while it's on AC power, and pause on battery.
    /// Remembered across launches.
    var onlyOnACPower: Bool {
        didSet {
            guard onlyOnACPower != oldValue else { return }
            defaults.set(onlyOnACPower, forKey: Self.onlyOnACPowerKey)
            pauseOrResume()
        }
    }

    private let service: any PowerAssertionService
    private let defaults: UserDefaults
    private let now: () -> Date
    private let sleep: (Duration) async throws -> Void
    private let appWatcher: any AppQuitWatcher
    private let powerSource: any PowerSourceService
    @ObservationIgnored private var holdID: UInt32?
    @ObservationIgnored private var endTask: Task<Void, Never>?

    private static let keepsDisplayOnKey = "keepsDisplayOn"
    private static let onlyOnACPowerKey = "onlyOnACPower"

    init(
        service: any PowerAssertionService = SystemPowerAssertions(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { .now },
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        appWatcher: any AppQuitWatcher = SystemAppQuitWatcher(),
        powerSource: any PowerSourceService = SystemPowerSource()
    ) {
        self.service = service
        self.defaults = defaults
        self.now = now
        self.sleep = sleep
        self.appWatcher = appWatcher
        self.powerSource = powerSource
        keepsDisplayOn = defaults.object(forKey: Self.keepsDisplayOnKey) as? Bool ?? true
        onlyOnACPower = defaults.bool(forKey: Self.onlyOnACPowerKey)
        powerSource.observeChanges { [weak self] in self?.pauseOrResume() }
    }

    /// Starts a session for `option`, replacing any active one.
    func start(_ option: DurationOption) {
        // Set first: if the hold is refused, `hold` turns off, which clears it again.
        activeOption = option
        hold(until: option.end(startingAt: now()))
        watchForTheAppToQuit()
    }

    /// Ends the session and releases its hold.
    func stop() {
        endTask?.cancel()
        endTask = nil
        appWatcher.stopWatching()
        releaseHold()
        state = .off
        activeOption = nil
        minutesLeft = nil
    }

    /// Holds the Mac awake in the current mode until `end` or, while the session must pause,
    /// holds nothing and keeps the session. A new hold is acquired before the previous one is
    /// released, so there is never a gap.
    private func hold(until end: SessionEnd) {
        let remaining = end.endDate.map { $0.timeIntervalSince(now()) }
        if let remaining, remaining <= 0 { return stop() }
        let paused = mustPause
        if paused {
            releaseHold()
        } else {
            do {
                let newID = try service.acquire(
                    keepsDisplayOn: keepsDisplayOn,
                    // Whole seconds, rounded up so a fraction of a second never becomes 0 (no timeout).
                    timeout: remaining?.rounded(.up) ?? 0,
                    details: holdDetails(until: end)
                )
                releaseHold()
                holdID = newID
            } catch {
                // Releases the previous hold too: Weiki never shows a session it isn't holding.
                return stop()
            }
        }
        state = .on(until: end, paused: paused)
        minutesLeft = remaining.map { Self.shownMinutes(remaining: $0) }
        scheduleEnd(at: end.endDate)
    }

    private func releaseHold() {
        if let holdID { service.release(holdID) }
        holdID = nil
    }

    /// Whether sessions must hold nothing: "Only on AC Power" is on and the Mac runs on battery.
    private var mustPause: Bool {
        onlyOnACPower && !powerSource.isOnACPower
    }

    /// Pauses or resumes the session after the power source or "Only on AC Power" changed.
    /// A report that doesn't change whether it must pause leaves the hold alone.
    private func pauseOrResume() {
        guard case .on(let end, let paused) = state, paused != mustPause else { return }
        hold(until: end)
    }

    /// Watches the app the session waits for, if any, and otherwise stops watching.
    private func watchForTheAppToQuit() {
        guard case .on(until: .appQuits(let app), _) = state else { return appWatcher.stopWatching() }
        appWatcher.watch(app) { [weak self] in self?.appDidQuit(app) }
    }

    /// Ends the session if it still waits for `app`. A late report, for an app the session no
    /// longer waits for, changes nothing.
    private func appDidQuit(_ app: WatchedApp) {
        guard case .on(until: .appQuits(app), _) = state else { return }
        stop()
    }

    /// What `pmset -g assertions` shows for the hold: the mode and when it ends.
    private func holdDetails(until end: SessionEnd) -> String {
        let mode = keepsDisplayOn ? "Display kept on" : "Display allowed to sleep"
        return switch end {
        case .never: "\(mode), indefinitely"
        case .date(let endDate): "\(mode), until \(endDate.endTimeDescription(now: now()))"
        case .appQuits(let app): "\(mode), until \(app.name) quits"
        }
    }

    /// Counts `minutesLeft` down and turns the session off once `endDate` passes. It wakes each
    /// time the shown minute changes — always within 60 s — and re-reads the clock, so a Mac
    /// that slept past the end turns off within a minute of waking. Stops early if the session
    /// is replaced or ended, or the controller goes away.
    private func scheduleEnd(at endDate: Date?) {
        endTask?.cancel()
        endTask = nil
        guard let endDate else { return }
        endTask = Task { [weak self, now, sleep] in
            while !Task.isCancelled, self != nil {
                let remaining = endDate.timeIntervalSince(now())
                guard remaining > 0 else { break }
                let minutes = Self.shownMinutes(remaining: remaining)
                self?.showMinutesLeft(minutes)
                try? await sleep(.seconds(remaining - Double(minutes - 1) * 60))
            }
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    /// Whole minutes shown for `remaining` seconds, rounded up: 41 min 10 s shows 42.
    private static func shownMinutes(remaining: TimeInterval) -> Int {
        Int((remaining / 60).rounded(.up))
    }

    /// Writes `minutesLeft` only when it changes, so the menu bar redraws once a minute.
    private func showMinutesLeft(_ minutes: Int) {
        if minutesLeft != minutes { minutesLeft = minutes }
    }
}
