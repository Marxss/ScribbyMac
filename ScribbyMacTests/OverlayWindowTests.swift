import AppKit
import XCTest
@testable import ScribbyMac

final class OverlayWindowTests: XCTestCase {
    @MainActor
    func testCommandZReachesAnnotationHistoryWithoutOpeningMenu() throws {
        let store = AnnotationStore()
        store.add(.text(TextAnnotation(origin: .zero, text: "test", color: .red)))
        let window = OverlayWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.onUndo = { store.undo() }
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: .command, timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "z", charactersIgnoringModifiers: "z",
            isARepeat: false, keyCode: 6))
        XCTAssertTrue(window.performKeyEquivalent(with: event))
        XCTAssertTrue(store.annotations.isEmpty)
    }
}
