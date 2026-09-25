import Testing
@testable import Weiki

/// A `LoginItemService` that records calls and plays macOS's part: it holds the
/// login-item status and changes it as registering and unregistering would.
final class FakeLoginItemService: LoginItemService {
    enum Call: Equatable { case register, unregister, openSystemSettings }
    struct Refused: Error {}

    private(set) var calls: [Call] = []
    var status: LoginItemStatus
    /// The status a successful `register()` leaves behind.
    var statusAfterRegister = LoginItemStatus.enabled
    var fails = false

    init(status: LoginItemStatus) {
        self.status = status
    }

    func register() throws {
        calls.append(.register)
        if fails { throw Refused() }
        status = statusAfterRegister
    }

    func unregister() throws {
        calls.append(.unregister)
        if fails { throw Refused() }
        status = .off
    }

    func openSystemSettings() {
        calls.append(.openSystemSettings)
    }
}

struct LoginItemTests {
    @Test func isOffAtLaunchWithoutRegistering() {
        let service = FakeLoginItemService(status: .off)

        let item = LoginItem(service: service)

        #expect(item.isEnabled == false)
        #expect(service.calls.isEmpty)
    }

    @Test func isCheckedWhenMacOSAlreadyHasIt() {
        let service = FakeLoginItemService(status: .enabled)

        let item = LoginItem(service: service)

        #expect(item.isEnabled)
        #expect(service.calls.isEmpty)
    }

    @Test func turningOnRegisters() {
        let service = FakeLoginItemService(status: .off)
        let item = LoginItem(service: service)

        item.setEnabled(true)

        #expect(service.calls == [.register])
        #expect(item.isEnabled)
    }

    @Test func turningOffUnregisters() {
        let service = FakeLoginItemService(status: .enabled)
        let item = LoginItem(service: service)

        item.setEnabled(false)

        #expect(service.calls == [.unregister])
        #expect(item.isEnabled == false)
    }

    @Test func needingApprovalOpensSystemSettingsAndStaysUnchecked() {
        let service = FakeLoginItemService(status: .requiresApproval)
        service.statusAfterRegister = .requiresApproval
        let item = LoginItem(service: service)

        item.setEnabled(true)

        #expect(service.calls == [.register, .openSystemSettings])
        #expect(item.isEnabled == false)
    }

    @Test func aRefusedRegistrationLeavesItUnchecked() {
        let service = FakeLoginItemService(status: .off)
        service.fails = true
        let item = LoginItem(service: service)

        item.setEnabled(true)

        #expect(item.isEnabled == false)
    }

    @Test func aRefusedUnregistrationLeavesItChecked() {
        let service = FakeLoginItemService(status: .enabled)
        service.fails = true
        let item = LoginItem(service: service)

        item.setEnabled(false)

        #expect(item.isEnabled)
    }
}
