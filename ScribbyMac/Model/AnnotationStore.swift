import Foundation

@MainActor
final class AnnotationStore {
    private enum UndoEntry {
        case removeLast
        case restore([Annotation])
    }

    private(set) var annotations: [Annotation] = []
    private(set) var selectedTool: DrawingTool = .arrow
    private(set) var selectedColor: AnnotationColor = .red
    private(set) var selectedStrokeWidth: StrokeWidth = .medium
    var onChange: (() -> Void)?
    private(set) var selectedTextSize: TextSize = .medium
    var onTextSizeChange: (() -> Void)?

    func select(textSize: TextSize) {
        selectedTextSize = textSize
        onTextSizeChange?()
    }

    private var undoEntries: [UndoEntry] = []

    var hasAnnotations: Bool { !annotations.isEmpty }
    var canUndo: Bool { !undoEntries.isEmpty }

    func add(_ annotation: Annotation) {
        annotations.append(annotation)
        undoEntries.append(.removeLast)
        onChange?()
    }

    func clear() {
        guard !annotations.isEmpty else { return }
        undoEntries.append(.restore(annotations))
        annotations.removeAll()
        onChange?()
    }

    func undo() {
        guard let entry = undoEntries.popLast() else { return }
        switch entry {
        case .removeLast:
            if !annotations.isEmpty {
                annotations.removeLast()
            }
        case let .restore(snapshot):
            annotations = snapshot
        }
        onChange?()
    }

    func select(tool: DrawingTool) {
        selectedTool = tool
    }

    func select(color: AnnotationColor) {
        selectedColor = color
    }

    func select(strokeWidth: StrokeWidth) {
        selectedStrokeWidth = strokeWidth
    }
}
