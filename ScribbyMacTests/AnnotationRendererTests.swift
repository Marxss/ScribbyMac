import XCTest
@testable import ScribbyMac

final class AnnotationRendererTests: XCTestCase {
    func testFreehandPathFollowsEveryPointWithoutClosing() throws {
        let points = [CGPoint.zero, CGPoint(x: 20, y: 40), CGPoint(x: 50, y: 10)]
        let path = try XCTUnwrap(AnnotationRenderer.path(for: .freehand(
            FreehandAnnotation(points: points, style: style))))
        var renderedPoints: [CGPoint] = []
        var types: [CGPathElementType] = []
        path.applyWithBlock { element in
            types.append(element.pointee.type)
            renderedPoints.append(element.pointee.points[0])
        }
        XCTAssertEqual(types, [.moveToPoint, .addLineToPoint, .addLineToPoint])
        XCTAssertEqual(renderedPoints, points)
    }

    private let style = DrawingStyle(color: .red, strokeWidth: .medium)

    func testRectanglePathMatchesAnnotationBounds() throws {
        let rect = CGRect(x: 10, y: 20, width: 80, height: 40)
        let path = try XCTUnwrap(AnnotationRenderer.path(for: .rectangle(
            RectangleAnnotation(rect: rect, style: style)
        )))
        XCTAssertEqual(path.boundingBox, rect)
    }

    func testArrowPathContainsShaftAndBothWings() throws {
        let arrow = ArrowAnnotation(
            start: CGPoint(x: 10, y: 10),
            end: CGPoint(x: 90, y: 50),
            style: style
        )
        let head = try XCTUnwrap(AnnotationGeometry.arrowHead(
            from: arrow.start,
            to: arrow.end,
            strokeWidth: arrow.style.strokeWidth.rawValue
        ))
        let path = try XCTUnwrap(AnnotationRenderer.path(for: .arrow(arrow)))
        let bounds = path.boundingBox

        for point in [arrow.start, arrow.end, head.left, head.right] {
            XCTAssertTrue(bounds.insetBy(dx: -0.001, dy: -0.001).contains(point))
        }
    }

    func testTextHasNoVectorPath() {
        XCTAssertNil(AnnotationRenderer.path(for: .text(TextAnnotation(
            origin: .zero,
            text: "文字",
            color: .blue
        ))))
    }
}
