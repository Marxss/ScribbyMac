import XCTest
@testable import ScribbyMac

final class AnnotationStoreTests: XCTestCase {
    @MainActor
    func testUndoRemovesAddedAnnotationsInReverseOrder() {
        let store = AnnotationStore()
        let annotations = [rectangle(x: 1), rectangle(x: 2), rectangle(x: 3)]
        annotations.forEach(store.add)

        store.undo()
        XCTAssertEqual(store.annotations, Array(annotations.prefix(2)))
        store.undo()
        XCTAssertEqual(store.annotations, Array(annotations.prefix(1)))
        store.undo()
        XCTAssertTrue(store.annotations.isEmpty)
        XCTAssertFalse(store.canUndo)
    }

    @MainActor
    func testUndoAfterClearRestoresTheEntireSnapshot() {
        let store = AnnotationStore()
        let first = rectangle(x: 1)
        let second = Annotation.text(TextAnnotation(
            origin: CGPoint(x: 20, y: 30),
            text: "重点",
            color: .yellow
        ))
        store.add(first)
        store.add(second)

        store.clear()
        XCTAssertTrue(store.annotations.isEmpty)
        store.undo()

        XCTAssertEqual(store.annotations, [first, second])
    }

    @MainActor
    func testEmptyClearAndUndoAreNoOps() {
        let store = AnnotationStore()
        store.clear()
        store.undo()
        XCTAssertTrue(store.annotations.isEmpty)
        XCTAssertFalse(store.canUndo)
    }

    @MainActor
    func testSelectionsDoNotEnterUndoHistory() {
        let store = AnnotationStore()
        store.select(tool: .text)
        store.select(color: .blue)
        store.select(strokeWidth: .thick)

        XCTAssertEqual(store.selectedTool, .text)
        XCTAssertEqual(store.selectedColor, .blue)
        XCTAssertEqual(store.selectedStrokeWidth, .thick)
        XCTAssertFalse(store.canUndo)
    }

    @MainActor
    func testOnChangeRunsOncePerAnnotationMutation() {
        let store = AnnotationStore()
        var changeCount = 0
        store.onChange = { changeCount += 1 }

        store.add(rectangle(x: 1))
        store.clear()
        store.undo()

        XCTAssertEqual(changeCount, 3)
    }

    private func rectangle(x: CGFloat) -> Annotation {
        .rectangle(RectangleAnnotation(
            rect: CGRect(x: x, y: 2, width: 8, height: 9),
            style: DrawingStyle(color: .red, strokeWidth: .medium)
        ))
    }
}
