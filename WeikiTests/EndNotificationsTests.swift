import Foundation
import Testing
@testable import Weiki

/// A `NotificationService` that plays macOS's part: it holds the permission, answers the
/// prompt as told, and records what was posted.
final class FakeNotificationService: NotificationService {
    var permissionState = NotificationPermission.notDetermined
    /// The user's answer when asked.
    var allowsWhenAsked = true
    private(set) var requests = 0
    private(set) var settingsOpened = 0
    private(set) var posts: [(title: String, body: String)] = []

    func permission() async -> NotificationPermission { permissionState }

    func requestPermission() async -> Bool {
        requests += 1
        permissionState = allowsWhenAsked ? .allowed : .denied
        return allowsWhenAsked
    }

    func openSettings() { settingsOpened += 1 }

    func post(title: String, body: String) { posts.append((title, body)) }
}

struct EndNotificationsTests {
    private let testDefaults = TestDefaults()
    private let service = FakeNotificationService()

    private func makeNotifications() async -> EndNotifications {
        let notifications = EndNotifications(service: service, defaults: testDefaults.defaults)
        await notifications.refresh()
        return notifications
    }

    @Test func isOffAtFirstLaunchWithoutAsking() async {
        let notifications = await makeNotifications()

        #expect(notifications.isEnabled == false)
        #expect(service.requests == 0)
    }

    @Test func turningItOnAsksOnceAndChecksItWhenAllowed() async {
        let notifications = await makeNotifications()

        await notifications.setEnabled(true)

        #expect(service.requests == 1)
        #expect(notifications.isEnabled)
        #expect(await makeNotifications().isEnabled)
    }

    @Test func decliningThePromptLeavesItUnchecked() async {
        let notifications = await makeNotifications()
        service.allowsWhenAsked = false

        await notifications.setEnabled(true)

        #expect(service.requests == 1)
        #expect(notifications.isEnabled == false)
    }

    @Test func choosingItAfterDecliningOpensSettings() async {
        service.permissionState = .denied
        let notifications = await makeNotifications()

        await notifications.setEnabled(true)

        #expect(service.settingsOpened == 1)
        #expect(service.requests == 0)
        #expect(notifications.isEnabled == false)
    }

    @Test func turningItOffUnchecksItAndIsRemembered() async {
        service.permissionState = .allowed
        let notifications = await makeNotifications()
        await notifications.setEnabled(true)

        await notifications.setEnabled(false)

        #expect(notifications.isEnabled == false)
        #expect(await makeNotifications().isEnabled == false)
    }

    /// Switched off in System Settings since it was turned on: unchecked at the next launch.
    @Test func isUncheckedWhenMacOSNoLongerAllowsIt() async {
        service.permissionState = .allowed
        await makeNotifications().setEnabled(true)
        service.permissionState = .denied

        #expect(await makeNotifications().isEnabled == false)
    }

    @Test func postsWhenATimerRunsOutWhileOn() async throws {
        service.permissionState = .allowed
        let notifications = await makeNotifications()
        await notifications.setEnabled(true)

        notifications.timerRanOut(at: .now)

        let post = try #require(service.posts.first)
        #expect(service.posts.count == 1)
        #expect(post.title == "Weiki is off")
        #expect(post.body.hasPrefix("The session ended at "))
    }

    @Test func postsNothingWhileOff() async {
        service.permissionState = .allowed
        let notifications = await makeNotifications()

        notifications.timerRanOut(at: .now)

        #expect(service.posts.isEmpty)
    }
}
