import AppKit

enum DrawingTool: CaseIterable, Hashable {
    case arrow
    case rectangle
    case text
}

enum AnnotationColor: CaseIterable, Hashable {
    case red
    case yellow
    case green
    case blue
    case white
    case black

    var nsColor: NSColor {
        switch self {
        case .red: .systemRed
        case .yellow: .systemYellow
        case .green: .systemGreen
        case .blue: .systemBlue
        case .white: .white
        case .black: .black
        }
    }
}

enum StrokeWidth: CGFloat, CaseIterable, Hashable {
    case thin = 2
    case medium = 4
    case thick = 8
}

struct DrawingStyle: Equatable {
    let color: AnnotationColor
    let strokeWidth: StrokeWidth
}

struct ArrowAnnotation: Equatable {
    let start: CGPoint
    let end: CGPoint
    let style: DrawingStyle
}

struct RectangleAnnotation: Equatable {
    let rect: CGRect
    let style: DrawingStyle
}

struct TextAnnotation: Equatable {
    let origin: CGPoint
    let text: String
    let color: AnnotationColor
    let fontSize: CGFloat

    init(origin: CGPoint, text: String, color: AnnotationColor, fontSize: CGFloat = 24) {
        self.origin = origin
        self.text = text
        self.color = color
        self.fontSize = fontSize
    }
}

enum Annotation: Equatable {
    case arrow(ArrowAnnotation)
    case rectangle(RectangleAnnotation)
    case text(TextAnnotation)
}
