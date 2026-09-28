import AppKit
import UserNotifications

/// Weiki's notifications through `UNUserNotificationCenter` — the only code that imports
/// UserNotifications. Reading the permission never prompts; only `requestPermission()` does.
final class SystemNotificationService: NotificationService {
    private let center = UNUserNotificationCenter.current()
    /// The center holds its delegate weakly.
    private let presenter = BannerPresenter()

    init() {
        center.delegate = presenter
    }

    func permission() async -> NotificationPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .authorized, .provisional: .allowed
        case .denied: .denied
        // Counted as denied, so the item never shows as on when it may not be.
        @unknown default: .denied
        }
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func openSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)") else { return }
        NSWorkspace.shared.open(url)
    }

    func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

/// Shows the banner even while Weiki is the active app, as it is while the Custom window is
/// open. Its own `NSObject`: a main-actor class as the delegate doesn't compile under Swift 6.
private nonisolated final class BannerPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
