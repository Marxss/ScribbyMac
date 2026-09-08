import CoreGraphics

enum AnnotationGeometry {
    static let minimumShapeSize: CGFloat = 4
    private static let arrowHeadAngle = 28 * CGFloat.pi / 180

    static func normalizedRectangle(from start: CGPoint, to end: CGPoint) -> CGRect? {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        guard rect.width >= minimumShapeSize, rect.height >= minimumShapeSize else {
            return nil
        }
        return rect
    }

    static func arrowHead(
        from start: CGPoint,
        to end: CGPoint,
        strokeWidth: CGFloat
    ) -> (left: CGPoint, right: CGPoint)? {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let length = hypot(deltaX, deltaY)
        guard length >= minimumShapeSize else { return nil }

        let wingLength = min(max(10, strokeWidth * 4), length * 0.45)
        let reverseAngle = atan2(deltaY, deltaX) + .pi
        return (
            point(from: end, length: wingLength, angle: reverseAngle + arrowHeadAngle),
            point(from: end, length: wingLength, angle: reverseAngle - arrowHeadAngle)
        )
    }

    private static func point(from origin: CGPoint, length: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: origin.x + cos(angle) * length,
            y: origin.y + sin(angle) * length
        )
    }
}
