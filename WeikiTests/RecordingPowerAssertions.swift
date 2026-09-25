import Foundation
@testable import Weiki

/// A `PowerAssertionService` that records every call, in order, instead of
/// touching the system, and can be told to refuse new holds.
final class RecordingPowerAssertions: PowerAssertionService {
    enum Call: Equatable {
        case acquire(keepsDisplayOn: Bool, timeout: TimeInterval)
        case release(UInt32)
    }

    struct RefusedHold: Error {}

    private(set) var calls: [Call] = []
    /// The `details` passed to each `acquire`, in order.
    private(set) var details: [String] = []
    /// Holds acquired and not yet released.
    private(set) var heldIDs: Set<UInt32> = []
    var refusesHolds = false
    private var nextID: UInt32 = 1

    func acquire(keepsDisplayOn: Bool, timeout: TimeInterval, details: String) throws -> UInt32 {
        calls.append(.acquire(keepsDisplayOn: keepsDisplayOn, timeout: timeout))
        self.details.append(details)
        if refusesHolds { throw RefusedHold() }
        let id = nextID
        nextID += 1
        heldIDs.insert(id)
        return id
    }

    func release(_ id: UInt32) {
        calls.append(.release(id))
        heldIDs.remove(id)
    }
}
