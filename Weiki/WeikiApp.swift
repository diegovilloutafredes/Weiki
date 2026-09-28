import SwiftUI

@main
struct WeikiApp: App {
    @State private var controller: AwakeController
    @State private var notifications: EndNotifications
    @State private var today = Today()
    @State private var runningApps = RunningApps()
    @State private var sleepBlockers = SleepBlockers()
    @State private var loginItem = LoginItem()

    init() {
        let notifications = EndNotifications()
        _notifications = State(initialValue: notifications)
        _controller = State(initialValue: AwakeController(onTimerEnd: { notifications.timerRanOut(at: $0) }))
        // Reading the permission never prompts.
        Task { await notifications.refresh() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                controller: controller,
                today: today,
                runningApps: runningApps,
                sleepBlockers: sleepBlockers,
                notifications: notifications,
                loginItem: loginItem
            )
        } label: {
            MenuBarLabel(controller: controller, today: today)
        }
        .menuBarExtraStyle(.menu)

        Window("Custom Duration", id: CustomDurationView.windowID) {
            CustomDurationView(controller: controller)
        }
        .windowResizability(.contentSize)
        // Under the Weiki icon, where "Custom…" was clicked; placed again each time it opens.
        .defaultWindowPlacement { content, context in
            let size = content.sizeThatFits(.unspecified)
            // NSEvent uses a bottom-left origin; window placement uses a top-left one.
            let mouse = NSEvent.mouseLocation
            let screenHeight = NSScreen.screens.first?.frame.height ?? 0
            let origin = CustomDurationView.origin(
                pointer: CGPoint(x: mouse.x, y: screenHeight - mouse.y),
                visibleRect: context.defaultDisplay.visibleRect,
                windowWidth: size.width
            )
            return WindowPlacement(origin, size: size)
        }
        // Only ever opened from the menu: never at launch, never restored on relaunch.
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}
