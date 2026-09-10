import CoreGraphics

enum DrawingDraft: Equatable {
    case arrow(start: CGPoint, current: CGPoint, style: DrawingStyle)
    case rectangle(start: CGPoint, current: CGPoint, style: DrawingStyle)
    case text(origin: CGPoint, style: DrawingStyle)
}

struct DrawingInteraction {
    private(set) var draft: DrawingDraft?

    mutating func begin(at point: CGPoint, tool: DrawingTool, style: DrawingStyle) {
        switch tool {
        case .arrow:
            draft = .arrow(start: point, current: point, style: style)
        case .rectangle:
            draft = .rectangle(start: point, current: point, style: style)
        case .text:
            draft = .text(origin: point, style: style)
        }
    }

    mutating func update(to point: CGPoint) {
        switch draft {
        case let .arrow(start, _, style):
            draft = .arrow(start: start, current: point, style: style)
        case let .rectangle(start, _, style):
            draft = .rectangle(start: start, current: point, style: style)
        case .text, .none:
            break
        }
    }

    mutating func finish(at point: CGPoint) -> Annotation? {
        switch draft {
        case let .arrow(start, _, style):
            draft = nil
            guard AnnotationGeometry.arrowHead(
                from: start,
                to: point,
                strokeWidth: style.strokeWidth.rawValue
            ) != nil else { return nil }
            return .arrow(ArrowAnnotation(start: start, end: point, style: style))
        case let .rectangle(start, _, style):
            draft = nil
            guard let rect = AnnotationGeometry.normalizedRectangle(from: start, to: point) else {
                return nil
            }
            return .rectangle(RectangleAnnotation(rect: rect, style: style))
        case .text, .none:
            return nil
        }
    }

    mutating func commitText(_ text: String, fontSize: CGFloat = 24) -> Annotation? {
        guard case let .text(origin, style) = draft else { return nil }
        draft = nil
        let trimmed = text.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return .text(TextAnnotation(origin: origin, text: trimmed, color: style.color, fontSize: fontSize))
    }

    mutating func cancel() {
        draft = nil
    }
}
