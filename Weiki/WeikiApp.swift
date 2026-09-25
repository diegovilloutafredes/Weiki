import SwiftUI

@main
struct WeikiApp: App {
    @State private var controller = AwakeController()
    @State private var today = Today()
    @State private var loginItem = LoginItem()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller, today: today, loginItem: loginItem)
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
