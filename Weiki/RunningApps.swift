import AppKit
import Observation

/// What Weiki reads from a running app; `NSRunningApplication` provides it.
protocol RunningAppInfo {
    var processIdentifier: pid_t { get }
    var localizedName: String? { get }
    var bundleIdentifier: String? { get }
    var activationPolicy: NSApplication.ActivationPolicy { get }
    var launchDate: Date? { get }
}

extension NSRunningApplication: RunningAppInfo {}

extension WatchedApp {
    /// `app`, or nil for a running app without a name.
    init?(_ app: some RunningAppInfo) {
        guard let name = app.localizedName else { return nil }
        self.init(processIdentifier: app.processIdentifier, name: name, bundleIdentifier: app.bundleIdentifier)
    }
}

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
        refreshWhenAMenuOpens { [weak self] in self?.refresh() }
    }

    /// Writes only a changed list, so an unchanged one doesn't re-render the menu.
    private func refresh() {
        let apps = Self.dockApps(from: NSWorkspace.shared.runningApplications)
        if apps != self.apps { self.apps = apps }
    }

    /// The apps with a Dock icon, sorted by name the way Finder sorts.
    static func dockApps(from runningApps: [some RunningAppInfo]) -> [WatchedApp] {
        runningApps
            .filter { $0.activationPolicy == .regular }
            .compactMap { WatchedApp($0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// The running copy of the app with `bundleIdentifier` that was launched last, with or
    /// without a Dock icon, or nil when none runs. This is how a shortcut finds the app it names.
    static func newestInstance(of bundleIdentifier: String, among runningApps: [some RunningAppInfo]) -> WatchedApp? {
        runningApps
            .filter { $0.bundleIdentifier == bundleIdentifier }
            .max { ($0.launchDate ?? .distantPast) < ($1.launchDate ?? .distantPast) }
            .flatMap { WatchedApp($0) }
    }
}
