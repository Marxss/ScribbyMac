import AppKit
import XCTest
@testable import ScribbyMac

final class ToolbarInteractionTests: XCTestCase {
    @MainActor
    func testToolSelectionRemainsHighlightedAfterMouseActionCompletes() throws {
        let store = AnnotationStore()
        let toolbar = ToolbarPanelController(store: store,
            onSelectTool: { store.select(tool: $0) }, onUndo: {}, onClear: {}, onDone: {})
        let content = try XCTUnwrap(toolbar.window?.contentView)
        XCTAssertGreaterThan(try XCTUnwrap(toolbar.window).level.rawValue, NSWindow.Level.floating.rawValue)
        let stack = try XCTUnwrap(content.subviews.first as? NSStackView)
        let rectangle = try XCTUnwrap(stack.arrangedSubviews.compactMap { $0 as? NSButton }
            .first { $0.toolTip == "矩形" })
        rectangle.performClick(nil)
        XCTAssertEqual(store.selectedTool, .rectangle)
        XCTAssertEqual(rectangle.state, .on)
        XCTAssertTrue((rectangle.cell as? NSButtonCell)?.showsStateBy.contains(.changeBackgroundCellMask) == true)
    }

    @MainActor
    func testLineWidthSelectionRemainsHighlightedAfterClick() throws {
        let store = AnnotationStore()
        let toolbar = ToolbarPanelController(store: store,
            onSelectTool: { store.select(tool: $0) }, onUndo: {}, onClear: {}, onDone: {})
        let content = try XCTUnwrap(toolbar.window?.contentView)
        let stack = try XCTUnwrap(content.subviews.first as? NSStackView)
        let thick = try XCTUnwrap(stack.arrangedSubviews.compactMap { $0 as? NSButton }
            .first { $0.toolTip == "线宽 8" })
        thick.performClick(nil)
        XCTAssertEqual(store.selectedStrokeWidth, .thick)
        XCTAssertEqual(thick.state, .on)
    }
}
