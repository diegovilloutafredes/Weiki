import AppKit

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

/// The running apps that appear in the Dock, for the "Until an App Quits" submenu and the apps
/// Shortcuts suggests. Weiki is a menu bar agent, so it's never among them.
enum RunningApps {
    /// The apps with a Dock icon right now.
    static func dockApps() -> [WatchedApp] {
        dockApps(from: NSWorkspace.shared.runningApplications)
    }

    /// The apps with a Dock icon among `runningApps`, sorted by name the way Finder sorts.
    static func dockApps(from runningApps: [some RunningAppInfo]) -> [WatchedApp] {
        runningApps
            .filter { $0.activationPolicy == .regular }
            .compactMap { WatchedApp($0) }
            .sortedLikeFinder(by: \.name)
    }
}
