import AppKit
import Testing
@testable import Weiki

struct RunningAppsTests {
    private struct App: RunningAppInfo {
        let processIdentifier: pid_t
        let localizedName: String?
        var bundleIdentifier: String?
        let activationPolicy: NSApplication.ActivationPolicy
    }

    /// Only apps with a Dock icon, in the order Finder sorts names (so "iTerm2" comes before
    /// "Safari", unlike a plain string comparison).
    @Test func listsDockAppsByName() {
        let apps = RunningApps.dockApps(from: [
            App(processIdentifier: 1, localizedName: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", activationPolicy: .regular),
            App(processIdentifier: 2, localizedName: "iTerm2", bundleIdentifier: "com.googlecode.iterm2", activationPolicy: .regular),
            App(processIdentifier: 3, localizedName: "Bartender", activationPolicy: .accessory),
            App(processIdentifier: 4, localizedName: "Safari", activationPolicy: .regular),
            App(processIdentifier: 5, localizedName: "coreauthd", activationPolicy: .prohibited),
            App(processIdentifier: 6, localizedName: nil, activationPolicy: .regular),
        ])

        #expect(apps == [
            WatchedApp(processIdentifier: 2, name: "iTerm2", bundleIdentifier: "com.googlecode.iterm2"),
            WatchedApp(processIdentifier: 4, name: "Safari"),
            WatchedApp(processIdentifier: 1, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode"),
        ])
    }

    @Test func twoCopiesOfAnAppAreBothListed() {
        let apps = RunningApps.dockApps(from: [
            App(processIdentifier: 11, localizedName: "Terminal", activationPolicy: .regular),
            App(processIdentifier: 12, localizedName: "Terminal", activationPolicy: .regular),
        ])

        #expect(apps.map(\.processIdentifier).sorted() == [11, 12])
    }
}
