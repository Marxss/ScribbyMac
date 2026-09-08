import CoreGraphics

enum AnnotationRenderer {
    static func path(for annotation: Annotation) -> CGPath? {
        let path = CGMutablePath()
        switch annotation {
        case let .arrow(arrow):
            guard let head = AnnotationGeometry.arrowHead(
                from: arrow.start,
                to: arrow.end,
                strokeWidth: arrow.style.strokeWidth.rawValue
            ) else { return nil }
            path.move(to: arrow.start)
            path.addLine(to: arrow.end)
            path.move(to: head.left)
            path.addLine(to: arrow.end)
            path.addLine(to: head.right)
        case let .rectangle(rectangle):
            path.addRect(rectangle.rect)
        case .text:
            return nil
        }
        return path
    }
}
