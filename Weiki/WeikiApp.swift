import SwiftUI

@main
struct WeikiApp: App {
    @State private var controller = AwakeController()
    @State private var today = Today()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: controller, today: today)
        } label: {
            MenuBarLabel(controller: controller, today: today)
        }
        .menuBarExtraStyle(.menu)

        Window("Custom Duration", id: CustomDurationView.windowID) {
            CustomDurationView(controller: controller)
        }
        .windowResizability(.contentSize)
        // Only ever opened from the menu: never at launch, never restored on relaunch.
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}
