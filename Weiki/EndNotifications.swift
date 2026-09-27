import Foundation
import Observation

/// What macOS allows for Weiki's notifications.
enum NotificationPermission {
    /// The user hasn't been asked yet.
    case notDetermined
    case allowed
    /// Declined at the prompt, or switched off in System Settings.
    case denied
}

/// Shows notifications through macOS; replaceable so tests never ask for permission or post.
protocol NotificationService {
    func permission() async -> NotificationPermission
    /// Asks the user, which macOS does only once; returns whether notifications are allowed.
    func requestPermission() async -> Bool
    /// Opens System Settings at Weiki's notification settings.
    func openSettings()
    func post(title: String, body: String)
}

/// "Notify When Time's Up". The item is checked only while the saved choice is on and macOS
/// allows Weiki's notifications, as read at launch (`refresh()`) and after each choice. Off by
/// default: macOS asks for permission only when the user turns it on.
@Observable
final class EndNotifications {
    private(set) var isEnabled = false
    private let service: any NotificationService
    private let defaults: UserDefaults

    private static let wantsNotificationsKey = "notifyWhenTimeIsUp"

    init(service: any NotificationService = SystemNotificationService(), defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
    }

    /// Reads the saved choice and macOS's permission again.
    func refresh() async {
        let permission = await service.permission()
        isEnabled = defaults.bool(forKey: Self.wantsNotificationsKey) && permission == .allowed
    }

    /// Turns the setting on or off. Turning it on asks for permission the first time; after the
    /// user declined, it opens System Settings instead and stays off.
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            switch await service.permission() {
            case .allowed: defaults.set(true, forKey: Self.wantsNotificationsKey)
            case .notDetermined: defaults.set(await service.requestPermission(), forKey: Self.wantsNotificationsKey)
            case .denied: service.openSettings()
            }
        } else {
            defaults.set(false, forKey: Self.wantsNotificationsKey)
        }
        await refresh()
    }

    /// Posts "Weiki is off" for a timed session that ran out at `endDate`, if the setting is on.
    func timerRanOut(at endDate: Date) {
        guard isEnabled else { return }
        service.post(
            title: String(localized: "Weiki is off"),
            body: String(localized: "The session ended at \(endDate.endTimeDescription(now: .now)).")
        )
    }
}
