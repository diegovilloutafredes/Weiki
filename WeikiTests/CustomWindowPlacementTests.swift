import CoreGraphics
import Testing
@testable import Weiki

/// Where the Custom window opens: just below the menu bar, centered on the pointer (which is
/// under the Weiki icon when "Custom…" is clicked), and kept on screen. Coordinates use a
/// top-left origin, like SwiftUI's window placement.
struct CustomWindowPlacementTests {
    /// A 1680×1050 display below a 30 pt menu bar.
    private let visibleRect = CGRect(x: 0, y: 30, width: 1680, height: 1020)
    private let width: CGFloat = 292

    private func origin(pointer: CGPoint, in rect: CGRect? = nil) -> CGPoint {
        CustomDurationView.origin(pointer: pointer, visibleRect: rect ?? visibleRect, windowWidth: width)
    }

    @Test func centersUnderThePointerJustBelowTheMenuBar() {
        #expect(origin(pointer: CGPoint(x: 1246, y: 203)) == CGPoint(x: 1100, y: 34))
    }

    @Test func staysOnScreenAtTheRightEdge() {
        #expect(origin(pointer: CGPoint(x: 1650, y: 100)) == CGPoint(x: 1380, y: 34))
    }

    @Test func staysOnScreenAtTheLeftEdge() {
        #expect(origin(pointer: CGPoint(x: 40, y: 100)) == CGPoint(x: 8, y: 34))
    }

    /// The menu was used from the keyboard, so the pointer says nothing about the icon.
    @Test func goesTopRightWhenThePointerIsFarFromTheMenuBar() {
        #expect(origin(pointer: CGPoint(x: 945, y: 677)) == CGPoint(x: 1380, y: 34))
    }

    @Test func staysOnASecondDisplay() {
        let second = CGRect(x: 1680, y: 25, width: 1920, height: 1055)

        #expect(origin(pointer: CGPoint(x: 1800, y: 150), in: second) == CGPoint(x: 1688, y: 29))
    }
}
