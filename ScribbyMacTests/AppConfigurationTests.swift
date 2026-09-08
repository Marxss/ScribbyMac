import XCTest
import Carbon.HIToolbox
@testable import ScribbyMac

final class AppConfigurationTests: XCTestCase {
    func testDefinesTheApprovedMinimumSystemAndHotKeyLabel() {
        XCTAssertEqual(AppConfiguration.minimumSystemMajor, 13)
        XCTAssertEqual(AppConfiguration.globalHotKeyDisplay, "⌘⇧D")
    }

    func testHotKeyUsesCommandShiftD() {
        XCTAssertEqual(AppConfiguration.hotKeyKeyCode, UInt32(kVK_ANSI_D))
        XCTAssertEqual(AppConfiguration.hotKeyModifiers, UInt32(cmdKey | shiftKey))
    }
}
