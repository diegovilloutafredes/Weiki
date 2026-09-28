import AppKit
import Testing
@testable import Weiki

/// A value that is current whenever one of the app's menus opens.
struct MenuOpenReadingTests {
    private final class Source {
        var value = 1
    }

    @Test func readsAtOnceAndAgainWhenAMenuOpens() async {
        let source = Source()
        let reading = MenuOpenReading { source.value }
        #expect(reading.value == 1)

        source.value = 2
        #expect(reading.value == 1)
        NotificationCenter.default.post(name: NSMenu.didBeginTrackingNotification, object: NSMenu())

        #expect(await waitUntil { reading.value == 2 })
    }
}
