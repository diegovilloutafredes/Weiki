import Foundation
import IOKit.pwr_mgt

/// Creates and releases the power assertions ("holds") that keep the Mac awake.
protocol PowerAssertionService {
    /// Creates a hold and returns its ID. `timeout` is in seconds; `0` means no timeout.
    func acquire(keepsDisplayOn: Bool, timeout: TimeInterval, details: String) throws -> UInt32
    /// Releases a hold. Best-effort: releasing one the system already timed out is harmless.
    func release(_ id: UInt32)
}

/// The IOKit return code of a hold the system refused to create.
struct PowerAssertionError: Error {
    let code: IOReturn
}

/// The system implementation — the only code in Weiki that talks to IOKit.
struct SystemPowerAssertions: PowerAssertionService {
    func acquire(keepsDisplayOn: Bool, timeout: TimeInterval, details: String) throws -> UInt32 {
        let type = keepsDisplayOn ? kIOPMAssertPreventUserIdleDisplaySleep : kIOPMAssertPreventUserIdleSystemSleep
        var id = IOPMAssertionID(0)
        // The timeout action must be explicit: IOKit's default is TurnOff, not Release.
        let result = IOPMAssertionCreateWithDescription(
            type as CFString,
            "Weiki" as CFString,
            details as CFString,
            nil,
            nil,
            timeout,
            kIOPMAssertionTimeoutActionRelease as CFString,
            &id
        )
        guard result == kIOReturnSuccess else { throw PowerAssertionError(code: result) }
        return id
    }

    func release(_ id: UInt32) {
        // Ignored on purpose: a hold whose timeout already fired returns kIOReturnBadArgument.
        _ = IOPMAssertionRelease(id)
    }
}
