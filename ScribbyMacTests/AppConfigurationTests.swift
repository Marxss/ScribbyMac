import XCTest
@testable import ScribbyMac

final class AppConfigurationTests: XCTestCase {
    func testDefinesTheApprovedMinimumSystemAndHotKeyLabel() {
        XCTAssertEqual(AppConfiguration.minimumSystemMajor, 13)
        XCTAssertEqual(AppConfiguration.globalHotKeyDisplay, "⌘⇧D")
    }
}
