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

/// What an assertion does toward keeping the Mac awake.
enum AssertionEffect {
    case keepsDisplayOn
    case keepsMacAwake
}

/// What one process's assertions keep awake, and the process name the system recorded.
struct ProcessAssertions: Equatable {
    let processName: String?
    /// Whether one of them keeps the display on; otherwise they keep only the Mac awake.
    let keepsDisplayOn: Bool
}

extension SystemPowerAssertions {
    /// Every process's assertions that are on and keep the Mac awake, by process ID. Processes
    /// with none are left out. Any process may read this.
    static func assertionsByProcess() -> [pid_t: ProcessAssertions] {
        var byProcess: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&byProcess) == kIOReturnSuccess,
              let assertionsByProcess = byProcess?.takeRetainedValue() as? [NSNumber: [[String: Any]]] else { return [:] }
        var result: [pid_t: ProcessAssertions] = [:]
        for (process, assertions) in assertionsByProcess {
            let effects = assertions.compactMap { assertion -> AssertionEffect? in
                guard (assertion[kIOPMAssertionLevelKey] as? NSNumber)?.uint32Value == IOPMAssertionLevel(kIOPMAssertionLevelOn),
                      let type = assertion[kIOPMAssertionTypeKey] as? String else { return nil }
                return effect(ofType: type)
            }
            guard !effects.isEmpty else { continue }
            // Each assertion carries its process's name under this key, which IOPMLib.h doesn't
            // declare; it's what `pmset -g assertions` shows, even for processes owned by root.
            let processName = assertions.first?["Process Name"] as? String
            result[process.int32Value] = ProcessAssertions(processName: processName, keepsDisplayOn: effects.contains(.keepsDisplayOn))
        }
        return result
    }

    /// What an assertion of `type` keeps awake, or nil for types that don't keep the Mac from
    /// idle-sleeping, including macOS's own bookkeeping (`Internal…`, `UserIsActive`).
    static func effect(ofType type: String) -> AssertionEffect? {
        switch type {
        case kIOPMAssertPreventUserIdleDisplaySleep, kIOPMAssertionTypeNoDisplaySleep:
            .keepsDisplayOn
        case kIOPMAssertPreventUserIdleSystemSleep, kIOPMAssertionTypeNoIdleSleep,
             kIOPMAssertionTypePreventSystemSleep, kIOPMAssertNetworkClientActive:
            .keepsMacAwake
        default:
            nil
        }
    }
}
