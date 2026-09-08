import XCTest
@testable import ScribbyMac

final class AnnotationGeometryTests: XCTestCase {
    func testNormalizesReverseRectangleDrag() {
        XCTAssertEqual(
            AnnotationGeometry.normalizedRectangle(
                from: CGPoint(x: 20, y: 30),
                to: CGPoint(x: 5, y: 10)
            ),
            CGRect(x: 5, y: 10, width: 15, height: 20)
        )
    }

    func testRejectsRectangleWhenEitherSideIsTooSmall() {
        XCTAssertNil(AnnotationGeometry.normalizedRectangle(
            from: .zero,
            to: CGPoint(x: 3, y: 20)
        ))
        XCTAssertNil(AnnotationGeometry.normalizedRectangle(
            from: .zero,
            to: CGPoint(x: 20, y: 3)
        ))
    }

    func testRejectsTooSmallArrow() {
        XCTAssertNil(AnnotationGeometry.arrowHead(
            from: .zero,
            to: CGPoint(x: 3, y: 0),
            strokeWidth: 4
        ))
    }

    func testArrowHeadIsSymmetricAndGrowsWithStrokeWidth() throws {
        let end = CGPoint(x: 100, y: 0)
        let thin = try XCTUnwrap(AnnotationGeometry.arrowHead(
            from: .zero,
            to: end,
            strokeWidth: 2
        ))
        let thick = try XCTUnwrap(AnnotationGeometry.arrowHead(
            from: .zero,
            to: end,
            strokeWidth: 8
        ))

        XCTAssertEqual(thin.left.distance(to: end), thin.right.distance(to: end), accuracy: 0.001)
        XCTAssertGreaterThan(thick.left.distance(to: end), thin.left.distance(to: end))
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
