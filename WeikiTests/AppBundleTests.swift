import Foundation
import Testing

/// Weiki ships as a menu bar agent: no Dock icon and no app menu.
@Test func appIsAMenuBarAgent() {
    #expect(Bundle.main.bundleIdentifier == "com.weiki.app")
    #expect(Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true)
}
