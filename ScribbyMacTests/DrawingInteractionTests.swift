import XCTest
@testable import ScribbyMac

final class DrawingInteractionTests: XCTestCase {
    func testFreehandPreservesDraggedPointsAndReleasePoint() {
        var interaction = DrawingInteraction()
        let middle = CGPoint(x: 20, y: 30)
        let end = CGPoint(x: 40, y: 5)
        interaction.begin(at: .zero, tool: .freehand, style: redMedium)
        interaction.update(to: middle)
        interaction.update(to: middle)
        XCTAssertEqual(interaction.draft, .freehand(points: [.zero, middle], style: redMedium))
        XCTAssertEqual(interaction.finish(at: end),
            .freehand(FreehandAnnotation(points: [.zero, middle, end], style: redMedium)))
        XCTAssertNil(interaction.draft)
    }

    func testFreehandAllowsClosedLoopsAndRejectsClickWithoutDragging() {
        var interaction = DrawingInteraction()
        interaction.begin(at: .zero, tool: .freehand, style: redMedium)
        XCTAssertNil(interaction.finish(at: .zero))
        XCTAssertNil(interaction.draft)
        interaction.begin(at: .zero, tool: .freehand, style: redMedium)
        interaction.update(to: CGPoint(x: 20, y: 30))
        XCTAssertNotNil(interaction.finish(at: .zero))
        interaction.begin(at: .zero, tool: .freehand, style: redMedium)
        interaction.cancel()
        XCTAssertNil(interaction.finish(at: CGPoint(x: 20, y: 30)))
    }

    @MainActor
    func testFreehandIsUndoneAsOneStrokeAndRestoredAfterClear() throws {
        var interaction = DrawingInteraction()
        interaction.begin(at: .zero, tool: .freehand, style: redMedium)
        interaction.update(to: CGPoint(x: 10, y: 20))
        let annotation = try XCTUnwrap(interaction.finish(at: CGPoint(x: 30, y: 10)))
        let store = AnnotationStore()
        store.add(annotation)
        store.clear()
        store.undo()
        XCTAssertEqual(store.annotations, [annotation])
        store.undo()
        XCTAssertTrue(store.annotations.isEmpty)
    }

    func testPastedMultilineTextIsCommittedAsSingleLine() {
        var interaction = DrawingInteraction()
        interaction.begin(at: .zero, tool: .text, style: DrawingStyle(color: .red, strokeWidth: .medium))
        guard case let .text(text) = interaction.commitText("第一行\n第二行\r\n第三行") else {
            return XCTFail("Expected committed text")
        }
        XCTAssertEqual(text.text, "第一行 第二行 第三行")
    }
    private let redMedium = DrawingStyle(color: .red, strokeWidth: .medium)

    func testArrowGestureProducesAnnotation() {
        var interaction = DrawingInteraction()
        interaction.begin(at: .zero, tool: .arrow, style: redMedium)
        interaction.update(to: CGPoint(x: 20, y: 10))

        XCTAssertEqual(
            interaction.finish(at: CGPoint(x: 30, y: 15)),
            .arrow(ArrowAnnotation(
                start: .zero,
                end: CGPoint(x: 30, y: 15),
                style: redMedium
            ))
        )
        XCTAssertNil(interaction.draft)
    }

    func testRectangleNormalizesAndRejectsShortShapes() {
        var interaction = DrawingInteraction()
        interaction.begin(at: CGPoint(x: 20, y: 30), tool: .rectangle, style: redMedium)
        XCTAssertEqual(
            interaction.finish(at: CGPoint(x: 5, y: 10)),
            .rectangle(RectangleAnnotation(
                rect: CGRect(x: 5, y: 10, width: 15, height: 20),
                style: redMedium
            ))
        )

        interaction.begin(at: .zero, tool: .arrow, style: redMedium)
        XCTAssertNil(interaction.finish(at: CGPoint(x: 3, y: 0)))
        interaction.begin(at: .zero, tool: .rectangle, style: redMedium)
        XCTAssertNil(interaction.finish(at: CGPoint(x: 3, y: 20)))
    }

    func testTextWaitsForInputAndIgnoresDragUpdates() {
        var interaction = DrawingInteraction()
        let origin = CGPoint(x: 12, y: 18)
        interaction.begin(at: origin, tool: .text, style: redMedium)
        interaction.update(to: CGPoint(x: 100, y: 100))

        XCTAssertEqual(interaction.draft, .text(origin: origin, style: redMedium))
        XCTAssertNil(interaction.finish(at: CGPoint(x: 100, y: 100)))
        XCTAssertEqual(interaction.draft, .text(origin: origin, style: redMedium))
    }

    func testCommitTextTrimsAndRejectsEmptyInput() {
        var interaction = DrawingInteraction()
        interaction.begin(at: CGPoint(x: 8, y: 9), tool: .text, style: redMedium)
        XCTAssertEqual(
            interaction.commitText("  重点  \n"),
            .text(TextAnnotation(
                origin: CGPoint(x: 8, y: 9),
                text: "重点",
                color: .red
            ))
        )

        interaction.begin(at: .zero, tool: .text, style: redMedium)
        XCTAssertNil(interaction.commitText("  \n"))
        XCTAssertNil(interaction.draft)
    }

    func testCancelClearsAnyDraftAndStyleIsCapturedAtBegin() {
        let initial = DrawingStyle(color: .blue, strokeWidth: .thin)
        var interaction = DrawingInteraction()
        interaction.begin(at: .zero, tool: .arrow, style: initial)
        interaction.update(to: CGPoint(x: 20, y: 0))
        XCTAssertEqual(
            interaction.finish(at: CGPoint(x: 20, y: 0)),
            .arrow(ArrowAnnotation(start: .zero, end: CGPoint(x: 20, y: 0), style: initial))
        )

        interaction.begin(at: .zero, tool: .rectangle, style: redMedium)
        interaction.cancel()
        XCTAssertNil(interaction.draft)
        interaction.begin(at: .zero, tool: .text, style: redMedium)
        interaction.cancel()
        XCTAssertNil(interaction.draft)
    }
}
