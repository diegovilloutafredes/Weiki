import AppKit
import Observation

/// A process keeping the Mac awake, as the menu lists it.
struct SleepBlocker: Hashable, Identifiable {
    let name: String
    let keepsDisplayOn: Bool

    var id: String { name }
}

/// The other processes keeping the Mac awake, for the "Also Keeping the Mac Awake" section.
///
/// It refreshes each time a menu opens, because a `.menu`-style menu only re-renders when
/// observed state changes and nothing announces a change in the system's assertions.
@Observable
final class SleepBlockers {
    private(set) var list: [SleepBlocker] = []

    init() {
        refresh()
        refreshWhenAMenuOpens { [weak self] in self?.refresh() }
    }

    /// Writes only a changed list, so an unchanged one doesn't re-render the menu.
    private func refresh() {
        let list = Self.list(
            from: SystemPowerAssertions.assertionsByProcess(),
            appName: { NSRunningApplication(processIdentifier: $0)?.localizedName },
            excluding: ProcessInfo.processInfo.processIdentifier
        )
        if list != self.list { self.list = list }
    }

    /// One item per name, sorted the way Finder sorts. A process goes by its app's name when it
    /// has one (`appName`), and otherwise by its process name. Leaves out `ownProcess` and
    /// `powerd`, the power manager, whose assertions are the system's bookkeeping. A process
    /// that keeps both the display and the Mac awake reads as keeping the display on.
    static func list(
        from assertions: [pid_t: ProcessAssertions],
        appName: (pid_t) -> String?,
        excluding ownProcess: pid_t
    ) -> [SleepBlocker] {
        var keepsDisplayOnByName: [String: Bool] = [:]
        for (process, processAssertions) in assertions where process != ownProcess && !processAssertions.effects.isEmpty {
            guard processAssertions.processName != "powerd",
                  let name = appName(process) ?? processAssertions.processName else { continue }
            let keepsDisplayOn = processAssertions.effects.contains(.keepsDisplayOn)
            keepsDisplayOnByName[name] = (keepsDisplayOnByName[name] ?? false) || keepsDisplayOn
        }
        return keepsDisplayOnByName
            .map { SleepBlocker(name: $0.key, keepsDisplayOn: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
