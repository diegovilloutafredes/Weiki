import SwiftUI

/// The "Custom…" window: choose hours and minutes, then Start.
struct CustomDurationView: View {
    static let windowID = "custom-duration"

    let controller: AwakeController
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var hours = 0
    @State private var minutes = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep the Mac awake for:")
            HStack {
                Picker("Hours", selection: $hours) {
                    ForEach(0...24, id: \.self) { Text("\($0)") }
                }
                .labelsHidden()
                Text("h")
                Picker("Minutes", selection: $minutes) {
                    ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { Text("\($0)") }
                }
                .labelsHidden()
                Text("min")
                Button("Start") {
                    controller.start(.custom(TimeInterval(hours * 3600 + minutes * 60)))
                    dismissWindow(id: Self.windowID)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(hours == 0 && minutes == 0)
                .padding(.leading, 8)
            }
        }
        .padding(20)
        // The window hugs its content (.windowResizability(.contentSize)).
        .fixedSize()
        // A Window scene keeps its state across close and reopen; always open at 0 h 30 min.
        .onAppear {
            hours = 0
            minutes = 30
        }
    }
}
