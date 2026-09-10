import AppKit
import XCTest
@testable import ScribbyMac

final class TextEditorLayoutTests: XCTestCase {
    @MainActor
    func testTextEditorAtTopRightStaysInsideCanvas() throws {
        let store = AnnotationStore()
        store.select(tool: .text)
        let canvas = DrawingCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), store: store)
        let window = OverlayWindow(frame: canvas.frame)
        window.contentView = canvas
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown,
            location: CGPoint(x: 795, y: 595), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        canvas.mouseDown(with: event)
        let editor = try XCTUnwrap(canvas.subviews.first as? NSTextField)
        XCTAssertTrue(canvas.bounds.contains(editor.frame))
        XCTAssertEqual(editor.frame.minX, 795)
        canvas.cancelPendingInteraction()
    }
}
