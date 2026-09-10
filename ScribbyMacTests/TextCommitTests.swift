import AppKit
import XCTest
@testable import ScribbyMac

final class TextCommitTests: XCTestCase {
    @MainActor
    func testFocusLossCommitsExactlyOnceAtSelectedSize() throws {
        let store = AnnotationStore()
        store.select(tool: .text)
        let canvas = DrawingCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), store: store)
        let window = OverlayWindow(frame: canvas.frame)
        window.contentView = canvas
        let event = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown,
            location: CGPoint(x: 100, y: 100), modifierFlags: [], timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        canvas.mouseDown(with: event)
        let field = try XCTUnwrap(canvas.subviews.first as? NSTextField)
        field.stringValue = "保留文字"
        field.currentEditor()?.string = "保留文字"
        store.select(textSize: .large)
        XCTAssertEqual(field.font?.pointSize, 36)
        canvas.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: field))
        canvas.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification, object: field))
        XCTAssertEqual(store.annotations.count, 1)
        guard case let .text(text) = store.annotations.first else { return XCTFail("Missing text") }
        XCTAssertEqual(text.text, "保留文字")
        XCTAssertEqual(text.fontSize, 36)
        store.undo()
        XCTAssertTrue(store.annotations.isEmpty)
    }

    @MainActor
    func testToolbarReusesSizeControlsAndPreservesLineWidth() throws {
        let store = AnnotationStore()
        store.select(tool: .text)
        let toolbar = ToolbarPanelController(store: store, onSelectTool: { store.select(tool: $0) }, onUndo: {}, onClear: {}, onDone: {})
        let stack = try XCTUnwrap(toolbar.window?.contentView?.subviews.first as? NSStackView)
        let buttons = stack.arrangedSubviews.compactMap { $0 as? NSButton }
        let size = try XCTUnwrap(buttons.first { $0.toolTip == "字号 36" })
        size.performClick(nil)
        XCTAssertEqual(store.selectedTextSize, .large)
        XCTAssertEqual(store.selectedStrokeWidth, .medium)
        store.select(tool: .rectangle)
        toolbar.refresh()
        XCTAssertEqual(size.title, "8")
        store.select(tool: .text)
        toolbar.refresh()
        XCTAssertEqual(size.title, "36")
        XCTAssertEqual(size.state, .on)
    }
}
