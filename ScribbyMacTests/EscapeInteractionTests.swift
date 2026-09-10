import AppKit
import XCTest
@testable import ScribbyMac

final class EscapeInteractionTests: XCTestCase {
    @MainActor
    func testEscapeCancelsTextThenRequestsExitOnNextPress() throws {
        let store = AnnotationStore()
        store.select(tool: .text)
        let canvas = DrawingCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), store: store)
        let window = OverlayWindow(frame: canvas.frame)
        window.contentView = canvas
        var exitCount = 0
        canvas.onEndDrawingRequested = { exitCount += 1 }
        window.onEscape = { canvas.cancelOperation(nil) }
        let click = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown,
            location: CGPoint(x: 100, y: 100), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        canvas.mouseDown(with: click)
        let field = try XCTUnwrap(canvas.subviews.first as? NSTextField)
        field.stringValue = "取消这段文字"
        let escape = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "\u{1b}", charactersIgnoringModifiers: "\u{1b}",
            isARepeat: false, keyCode: 53))
        window.keyDown(with: escape)
        XCTAssertEqual(exitCount, 0)
        XCTAssertTrue(store.annotations.isEmpty)
        XCTAssertTrue(canvas.subviews.isEmpty)
        window.keyDown(with: escape)
        XCTAssertEqual(exitCount, 1)
    }
}
