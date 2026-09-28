import AppKit
import Observation

/// A process keeping the Mac awake, as the menu lists it.
struct SleepBlocker: Hashable, Identifiable {
    let name: String
    let keepsDisplayOn: Bool

    var id: String { name }
}

/// The other processes keeping the Mac awake, for the "Also Keeping the Mac Awake" section.
enum SleepBlockers {
    /// The other processes keeping the Mac awake right now.
    static func current() -> [SleepBlocker] {
        list(
            from: SystemPowerAssertions.assertionsByProcess(),
            appName: { NSRunningApplication(processIdentifier: $0)?.localizedName },
            excluding: ProcessInfo.processInfo.processIdentifier
        )
    }

    /// One item per name, sorted the way Finder sorts. A process goes by its app's name when it
    /// has one (`appName`), and otherwise by its process name. Leaves out `ownProcess` and
    /// `powerd`, the power manager, whose assertions are the system's bookkeeping. Processes
    /// that share a name read as keeping the display on when any of them does.
    static func list(
        from assertions: [pid_t: ProcessAssertions],
        appName: (pid_t) -> String?,
        excluding ownProcess: pid_t
    ) -> [SleepBlocker] {
        var keepsDisplayOnByName: [String: Bool] = [:]
        for (process, processAssertions) in assertions where process != ownProcess {
            guard processAssertions.processName != "powerd",
                  let name = appName(process) ?? processAssertions.processName else { continue }
            keepsDisplayOnByName[name] = (keepsDisplayOnByName[name] ?? false) || processAssertions.keepsDisplayOn
        }
        return keepsDisplayOnByName
            .map { SleepBlocker(name: $0.key, keepsDisplayOn: $0.value) }
            .sortedLikeFinder(by: \.name)
    }
}
