import SwiftUI

/// The pull-down menu. `.menu`-style content is snapshotted into an `NSMenu`, so the
/// status line shows the end time rather than a countdown.
struct MenuContent: View {
    @Bindable var controller: AwakeController
    let today: Today
    let runningApps: RunningApps
    let sleepBlockers: SleepBlockers
    let notifications: EndNotifications
    let loginItem: LoginItem
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Text(controller.state.statusLine(now: today.date))
        if controller.state != .off {
            Button("Turn Off") { controller.stop() }
        }
        if !sleepBlockers.list.isEmpty {
            Section("Also Keeping the Mac Awake") {
                ForEach(sleepBlockers.list) { blocker in
                    if blocker.keepsDisplayOn {
                        Text("\(blocker.name) — keeps the display on")
                    } else {
                        Text("\(blocker.name) — keeps the Mac awake")
                    }
                }
            }
        }
        // A menu Section brings its own separators.
        Section("Keep Awake For") {
            Toggle("Indefinitely", isOn: isActive(.indefinitely))
            Toggle("15 Minutes", isOn: isActive(.fifteenMinutes))
            Toggle("1 Hour", isOn: isActive(.oneHour))
            Toggle("2 Hours", isOn: isActive(.twoHours))
            Toggle("Custom…", isOn: Binding(
                get: { if case .custom? = controller.activeOption { true } else { false } },
                set: { _ in openCustomDuration() }
            ))
            Menu("Until an App Quits") {
                if runningApps.apps.isEmpty {
                    Text("No Apps Running")
                } else {
                    ForEach(runningApps.apps) { app in
                        Toggle(app.name, isOn: isActive(.untilQuit(app)))
                    }
                }
            }
        }
        Toggle("Keep Display On", isOn: $controller.keepsDisplayOn)
        Toggle("Only on AC Power", isOn: $controller.onlyOnACPower)
        Toggle("Notify When Time's Up", isOn: Binding(
            get: { notifications.isEnabled },
            set: { enabled in Task { await notifications.setEnabled(enabled) } }
        ))
        Toggle("Launch at Login", isOn: Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        ))
        Divider()
        Button("Quit Weiki") { NSApplication.shared.terminate(nil) }
    }

    /// Checked while `option` started the active session. Choosing it, checked or not,
    /// starts that session from now.
    private func isActive(_ option: DurationOption) -> Binding<Bool> {
        Binding(
            get: { controller.activeOption == option },
            set: { _ in controller.start(option) }
        )
    }

    private func openCustomDuration() {
        // Reopen instead of just bringing it forward, so it always starts at 0 h 30 min.
        dismissWindow(id: CustomDurationView.windowID)
        openWindow(id: CustomDurationView.windowID)
        // A menu bar agent isn't brought forward on its own.
        NSApp.activate()
    }
}

/// The menu bar icon: a filled cup while a session holds the Mac awake, and an outlined one
/// while off or paused, followed by "∞", the time left ("42m"), or the app the session waits for.
struct MenuBarLabel: View {
    let controller: AwakeController
    let today: Today

    var body: some View {
        let state = controller.state
        Image(nsImage: MenuBarIcon.image(filled: state.isHolding, text: state.menuBarText(minutesLeft: controller.minutesLeft)))
            .accessibilityLabel(state == .off ? Text("Weiki, off") : Text("Weiki, \(state.statusLine(now: today.date))"))
    }
}

/// Draws the menu bar label as one template image — the cup, then optional text —
/// because a `MenuBarExtra` label can't reliably show an image and text side by side.
/// As a template, macOS tints it for light and dark menu bars and the open-menu highlight.
enum MenuBarIcon {
    /// `nonisolated`: AppKit may call an image's drawing handler off the main actor.
    nonisolated static func image(filled: Bool, text: String?) -> NSImage {
        let symbol = NSImage(
            systemSymbolName: filled ? "cup.and.saucer.fill" : "cup.and.saucer",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)) ?? NSImage()
        guard let text else {
            symbol.isTemplate = true
            return symbol
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.black,
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let spacing: CGFloat = 3
        let size = NSSize(
            width: symbol.size.width + spacing + textSize.width,
            height: max(symbol.size.height, textSize.height)
        )
        let image = NSImage(size: size, flipped: false) { rect in
            symbol.draw(in: NSRect(
                x: 0, y: (rect.height - symbol.size.height) / 2,
                width: symbol.size.width, height: symbol.size.height
            ))
            (text as NSString).draw(
                at: NSPoint(x: symbol.size.width + spacing, y: (rect.height - textSize.height) / 2),
                withAttributes: attributes
            )
            return true
        }
        image.isTemplate = true
        return image
    }
}
