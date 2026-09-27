import AppKit
import Observation

/// What the list reads from a running app; `NSRunningApplication` provides it.
protocol RunningAppInfo {
    var processIdentifier: pid_t { get }
    var localizedName: String? { get }
    var activationPolicy: NSApplication.ActivationPolicy { get }
}

extension NSRunningApplication: RunningAppInfo {}

/// The running apps that appear in the Dock, for the "Until an App Quits" submenu.
///
/// It follows apps launching and quitting, because a `.menu`-style menu only re-renders when
/// observed state changes. Weiki is a menu bar agent, so it's never in the list.
@Observable
final class RunningApps {
    private(set) var apps: [WatchedApp] = []

    init() {
        refresh()
        let changes = [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification]
        // Lives as long as the app, so the observers are never removed.
        for change in changes {
            _ = NSWorkspace.shared.notificationCenter.addObserver(forName: change, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
    }

    private func refresh() {
        apps = Self.dockApps(from: NSWorkspace.shared.runningApplications)
    }

    /// The apps with a Dock icon, sorted by name the way Finder sorts.
    static func dockApps(from runningApps: [some RunningAppInfo]) -> [WatchedApp] {
        runningApps
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in app.localizedName.map { WatchedApp(processIdentifier: app.processIdentifier, name: $0) } }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
