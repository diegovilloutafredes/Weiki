@testable import Weiki

/// A `PowerSourceService` that plays the Mac's part: setting `isOnACPower` is the Mac being
/// plugged in or unplugged, and reports the change as the system would.
final class FakePowerSource: PowerSourceService {
    var isOnACPower = true {
        didSet { onChange?() }
    }
    private var onChange: (@MainActor () -> Void)?

    func observeChanges(_ onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }
}
