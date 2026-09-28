import SwiftUI

extension CustomDurationView {
    /// How far below the menu bar the pointer can be and still be on Weiki's menu, which
    /// drops down from the icon. Farther away, the menu was used from the keyboard.
    private static let menuReach: CGFloat = 400
    private static let gapBelowMenuBar: CGFloat = 4
    private static let screenMargin: CGFloat = 8

    /// The window's top-left corner, in the top-left-origin coordinates SwiftUI's window
    /// placement uses: just below the menu bar, centered on `pointer` (under the Weiki icon
    /// when "Custom…" is clicked) and kept on screen, or at the top-right when the pointer
    /// is far from the menu bar.
    static func origin(pointer: CGPoint, visibleRect: CGRect, windowWidth: CGFloat) -> CGPoint {
        let minX = visibleRect.minX + screenMargin
        let maxX = visibleRect.maxX - windowWidth - screenMargin
        let isNearMenuBar = pointer.y - visibleRect.minY <= menuReach
        let x = isNearMenuBar ? pointer.x - windowWidth / 2 : maxX
        return CGPoint(x: min(max(x, minX), maxX), y: visibleRect.minY + gapBelowMenuBar)
    }
}

extension CustomDurationView {
    /// Seconds for a typed duration: "90" or "45m" (minutes), "2h", "1h30", "1h 30m", or
    /// "1:30", from 1 minute to 24 hours. Nil for anything else.
    static func duration(from text: String) -> TimeInterval? {
        let input = text.trimmingCharacters(in: .whitespaces).lowercased()
        let minutes: Int?
        if let match = input.wholeMatch(of: /(\d+)\s*(?:m|min)?/) {
            minutes = Int(match.1)
        } else if let match = input.wholeMatch(of: /(\d+)\s*h(?:\s*(\d+)\s*(?:m|min)?)?/) {
            minutes = totalMinutes(hours: match.1, minutes: match.2)
        } else if let match = input.wholeMatch(of: /(\d+):(\d\d)/) {
            minutes = totalMinutes(hours: match.1, minutes: match.2)
        } else {
            minutes = nil
        }
        guard let minutes else { return nil }
        // In TimeInterval, where a very long number can't overflow.
        let seconds = TimeInterval(minutes) * 60
        return DurationOption.customRange.contains(seconds) ? seconds : nil
    }

    /// Hours plus minutes, where the minutes must be under 60. Hours above 24 are
    /// rejected before multiplying, so a very long number can't overflow.
    private static func totalMinutes(hours: Substring, minutes: Substring?) -> Int? {
        guard let hours = Int(hours), hours <= 24 else { return nil }
        let minutes = minutes.flatMap { Int($0) } ?? 0
        guard minutes < 60 else { return nil }
        return hours * 60 + minutes
    }

    /// The line below the field: when a session would end, or a hint for text that isn't a duration.
    static func summary(for text: String, now: Date, calendar: Calendar = .autoupdatingCurrent, locale: Locale = .autoupdatingCurrent) -> String {
        guard let duration = duration(from: text) else { return String(localized: "Try 45m or 1h30") }
        let end = now.addingTimeInterval(duration).endTimeDescription(now: now, calendar: calendar, locale: locale)
        return String(localized: "Until \(end)")
    }
}

/// The "Custom…" window: type a duration, then Start.
struct CustomDurationView: View {
    static let windowID = "custom-duration"

    let controller: AwakeController
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var text = "30m"
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Keep the Mac awake for:")
            HStack {
                TextField("Duration", text: $text, prompt: Text("45m, 1h30, 1:30"))
                    .labelsHidden()
                    .frame(width: 160)
                    .focused($isFieldFocused)
                Button("Start", action: start)
                    .keyboardShortcut(.defaultAction)
                    .disabled(Self.duration(from: text) == nil)
            }
            // Keeps "Until 15:42" current while the window stays open.
            TimelineView(.everyMinute) { context in
                Text(Self.summary(for: text, now: context.date))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        // The window hugs its content (.windowResizability(.contentSize)).
        .fixedSize()
        // A Window scene keeps its state across close and reopen; always open with "30m".
        .onAppear {
            text = "30m"
            isFieldFocused = true
        }
        .onExitCommand { dismissWindow(id: Self.windowID) }
    }

    private func start() {
        guard let duration = Self.duration(from: text) else { return }
        controller.start(.custom(duration))
        dismissWindow(id: Self.windowID)
    }
}
