import AppKit
import IOKit.ps
import notify

/// Whether the Mac runs on AC power, and when that may have changed; replaceable so tests
/// never depend on the real power source.
protocol PowerSourceService {
    var isOnACPower: Bool { get }
    /// Calls `onChange` whenever the Mac may have switched between AC power and battery.
    func observeChanges(_ onChange: @escaping @MainActor () -> Void)
}

/// The Mac's power source, through IOKit's power-source API — the only code that reads it.
/// A Mac without a battery is always on AC power, and a UPS running on battery counts as
/// battery.
struct SystemPowerSource: PowerSourceService {
    var isOnACPower: Bool {
        IOPSGetTimeRemainingEstimate() == kIOPSTimeRemainingUnlimited
    }

    /// Lives as long as the app, so the registrations are never cancelled.
    func observeChanges(_ onChange: @escaping @MainActor () -> Void) {
        // Posted when the active source changes, and not as the battery level does.
        var token: Int32 = 0
        notify_register_dispatch(kIOPSNotifyPowerSource, &token, .main) { _ in
            MainActor.assumeIsolated { onChange() }
        }
        // A change during sleep can go unreported, so read the source again on wake.
        observeForever(NSWorkspace.didWakeNotification, in: NSWorkspace.shared.notificationCenter, onChange)
    }
}
