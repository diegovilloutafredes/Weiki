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
/// It refreshes each time a menu opens: a `.menu`-style menu only re-renders when observed
/// state changes, and an app can show or hide its Dock icon while it runs, which no launch or
/// quit notification reports. Weiki is a menu bar agent, so it's never in the list.
@Observable
final class RunningApps {
    private(set) var apps: [WatchedApp] = []

    init() {
        refresh()
        // Lives as long as the app, so the observer is never removed.
        _ = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
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
