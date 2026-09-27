import IOKit.ps
import Testing
@testable import Weiki

/// The real power source, checked against IOKit's other way of telling the same thing.
struct SystemPowerSourceTests {
    @Test func agreesWithTheProvidingPowerSource() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let providingSource = IOPSGetProvidingPowerSourceType(snapshot).takeUnretainedValue() as String

        #expect(SystemPowerSource().isOnACPower == (providingSource == kIOPMACPowerKey))
    }
}
