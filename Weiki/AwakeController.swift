import Foundation
import Observation

/// Keep-awake sessions: the current hold, when it ends, and the display-mode setting.
///
/// The end date is the source of truth for when a session ends. The timeout each hold
/// carries on the system side is only a safety net in case Weiki stops responding.
@Observable
final class AwakeController {
    enum State: Equatable {
        case off
        /// `until` is nil for an indefinite session.
        case on(until: Date?)
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
            if case .on(let endDate) = state { hold(until: endDate) }
        }
    }

    private let service: any PowerAssertionService
    private let defaults: UserDefaults
    private let now: () -> Date
    private let sleep: (Duration) async throws -> Void
    @ObservationIgnored private var holdID: UInt32?
    @ObservationIgnored private var endTask: Task<Void, Never>?

    private static let keepsDisplayOnKey = "keepsDisplayOn"

    init(
        service: any PowerAssertionService = SystemPowerAssertions(),
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = { .now },
        sleep: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.service = service
        self.defaults = defaults
        self.now = now
        self.sleep = sleep
        keepsDisplayOn = defaults.object(forKey: Self.keepsDisplayOnKey) as? Bool ?? true
    }

    /// Starts a session for `option`, replacing any active one.
    func start(_ option: DurationOption) {
        // Set first: if the hold is refused, `hold` turns off, which clears it again.
        activeOption = option
        hold(until: option.duration.map { now().addingTimeInterval($0) })
    }

    /// Ends the session and releases its hold.
    func stop() {
        endTask?.cancel()
        endTask = nil
        if let holdID { service.release(holdID) }
        holdID = nil
        state = .off
        activeOption = nil
        minutesLeft = nil
    }

    /// Holds the Mac awake in the current mode until `endDate`, or indefinitely when nil.
    /// The new hold is acquired before the previous one is released, so there is never a gap.
    private func hold(until endDate: Date?) {
        var timeout: TimeInterval = 0
        if let endDate {
            let remaining = endDate.timeIntervalSince(now())
            guard remaining > 0 else { return stop() }
            // Whole seconds, rounded up so a fraction of a second never becomes 0 (no timeout).
            timeout = remaining.rounded(.up)
        }
        do {
            let newID = try service.acquire(
                keepsDisplayOn: keepsDisplayOn,
                timeout: timeout,
                details: holdDetails(until: endDate)
            )
            if let holdID { service.release(holdID) }
            holdID = newID
            state = .on(until: endDate)
            minutesLeft = endDate.map { Self.shownMinutes(remaining: $0.timeIntervalSince(now())) }
            scheduleEnd(at: endDate)
        } catch {
            // Releases the previous hold too: Weiki never shows a session it isn't holding.
            stop()
        }
    }

    /// What `pmset -g assertions` shows for the hold: the mode and when it ends.
    private func holdDetails(until endDate: Date?) -> String {
        let mode = keepsDisplayOn ? "Display kept on" : "Display allowed to sleep"
        guard let endDate else { return "\(mode), indefinitely" }
        return "\(mode), until \(endDate.endTimeDescription(now: now()))"
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
