import Foundation

extension Sequence {
    /// Sorted by `name` the way Finder sorts names, so "iTerm2" comes before "Safari".
    func sortedLikeFinder(by name: (Element) -> String) -> [Element] {
        sorted { name($0).localizedStandardCompare(name($1)) == .orderedAscending }
    }
}
