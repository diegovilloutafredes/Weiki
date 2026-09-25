import Observation

/// Weiki's login-item state, as macOS reports it.
enum LoginItemStatus {
    case enabled
    /// Registered, but switched off by the user in System Settings > Login Items.
    case requiresApproval
    case off
}

/// Registers Weiki as a login item with macOS; replaceable so tests never touch the real one.
protocol LoginItemService {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

/// Whether Weiki starts at login. macOS is the source of truth: `isEnabled` is read from it
/// at launch and after each change, and nothing is stored separately. Off by default —
/// Weiki never registers itself.
@Observable
final class LoginItem {
    private(set) var isEnabled: Bool
    private let service: any LoginItemService

    init(service: any LoginItemService = SystemLoginItem()) {
        self.service = service
        isEnabled = service.status == .enabled
    }

    /// Registers or unregisters Weiki as a login item. When macOS needs the user's approval
    /// first, opens System Settings at Login Items.
    func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try service.register() } else { try service.unregister() }
        } catch {
            // Nothing to undo: the status read below is the truth either way. Unregistering an
            // item that's already gone throws, and a refused registration leaves it off.
        }
        let status = service.status
        if enabled, status == .requiresApproval { service.openSystemSettings() }
        isEnabled = status == .enabled
    }
}
