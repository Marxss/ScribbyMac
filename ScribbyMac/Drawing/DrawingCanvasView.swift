import AppKit

@MainActor
final class DrawingCanvasView: NSView, NSTextFieldDelegate {
    private let store: AnnotationStore
    private var interaction = DrawingInteraction()
    private weak var activeTextField: NSTextField?

    var borderVisible = false {
        didSet { needsDisplay = true }
    }
    var onAnnotationsChanged: (() -> Void)?
    var onEndDrawingRequested: (() -> Void)?

    override func cancelOperation(_ sender: Any?) {
        if activeTextField != nil {
            cancelPendingInteraction()
        } else {
            onEndDrawingRequested?()
        }
    }

    init(frame frameRect: NSRect = .zero, store: AnnotationStore) {
        self.store = store
        super.init(frame: frameRect)
        store.onTextSizeChange = { [weak self] in self?.updateTextEditorSize() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        for annotation in store.annotations {
            draw(annotation, in: context)
        }
        if let preview = previewAnnotation {
            draw(preview, in: context)
        }
        if borderVisible {
            context.saveGState()
            context.setStrokeColor(NSColor.systemRed.cgColor)
            context.setLineWidth(3)
            context.stroke(bounds.insetBy(dx: 1.5, dy: 1.5))
            context.restoreGState()
        }
    }

    override func mouseDown(with event: NSEvent) {
        commitPendingText()
        let point = convert(event.locationInWindow, from: nil)
        let style = DrawingStyle(
            color: store.selectedColor,
            strokeWidth: store.selectedStrokeWidth
        )
        if store.selectedTool == .text {
            cancelPendingInteraction()
            let origin = CGPoint(x: min(max(0, point.x), max(0, bounds.width - 1)),
                                 y: min(max(0, point.y), max(0, bounds.height - store.selectedTextSize.rawValue - 10)))
            interaction.begin(at: origin, tool: .text, style: style)
            beginTextEditing(at: origin, color: style.color)
        } else {
            interaction.begin(at: point, tool: store.selectedTool, style: style)
            needsDisplay = true
        }
    }

    override func mouseDragged(with event: NSEvent) {
        interaction.update(to: convert(event.locationInWindow, from: nil))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let annotation = interaction.finish(at: point) {
            store.add(annotation)
            onAnnotationsChanged?()
        }
        needsDisplay = true
    }

    func cancelPendingInteraction() {
        interaction.cancel()
        let editor = activeTextField
        activeTextField = nil
        editor?.removeFromSuperview()
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    func finishPendingInteraction() {
        commitPendingText()
        cancelPendingInteraction()
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.insertNewline(_:)):
            commitPendingText()
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            cancelPendingInteraction()
            return true
        default:
            return false
        }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        if activeTextField != nil {
            commitPendingText(restoreFocus: false)
        }
    }

    private var previewAnnotation: Annotation? {
        switch interaction.draft {
        case let .freehand(points, style):
            return .freehand(FreehandAnnotation(points: points, style: style))
        case let .arrow(start, current, style):
            guard AnnotationGeometry.arrowHead(
                from: start,
                to: current,
                strokeWidth: style.strokeWidth.rawValue
            ) != nil else { return nil }
            return .arrow(ArrowAnnotation(start: start, end: current, style: style))
        case let .rectangle(start, current, style):
            guard let rect = AnnotationGeometry.normalizedRectangle(from: start, to: current) else {
                return nil
            }
            return .rectangle(RectangleAnnotation(rect: rect, style: style))
        case .text, .none:
            return nil
        }
    }

    private func draw(_ annotation: Annotation, in context: CGContext) {
        if case let .text(text) = annotation {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: text.fontSize),
                .foregroundColor: text.color.nsColor,
            ]
            (text.text as NSString).draw(at: text.origin, withAttributes: attributes)
            return
        }

        guard let path = AnnotationRenderer.path(for: annotation),
              let style = annotation.style else { return }
        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(style.color.nsColor.cgColor)
        context.setLineWidth(style.strokeWidth.rawValue)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()
    }

    private func beginTextEditing(at origin: CGPoint, color: AnnotationColor) {
        let field = NSTextField(frame: CGRect(x: origin.x, y: origin.y, width: min(320, bounds.width - origin.x), height: min(34, bounds.height)))
        field.usesSingleLineMode = true
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: store.selectedTextSize.rawValue)
        field.textColor = color.nsColor
        field.delegate = self
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        addSubview(field)
        activeTextField = field
        updateTextEditorSize()
        window?.makeFirstResponder(field)
    }

    private func updateTextEditorSize() {
        guard let field = activeTextField else { return }
        let size = store.selectedTextSize.rawValue
        field.font = .systemFont(ofSize: size)
        field.currentEditor()?.font = field.font
        field.frame.size.height = min(size + 10, bounds.height - field.frame.minY)
    }

    private func commitPendingText(restoreFocus: Bool = true) {
        guard let field = activeTextField else { return }
        activeTextField = nil
        let text = field.currentEditor()?.string ?? field.stringValue
        let annotation = interaction.commitText(text, fontSize: store.selectedTextSize.rawValue)
        field.removeFromSuperview()
        if restoreFocus { window?.makeFirstResponder(self) }
        if let annotation {
            store.add(annotation)
            onAnnotationsChanged?()
        }
        needsDisplay = true
    }
}

private extension Annotation {
    var style: DrawingStyle? {
        switch self {
        case let .freehand(annotation): annotation.style
        case let .arrow(annotation): annotation.style
        case let .rectangle(annotation): annotation.style
        case .text: nil
        }
    }
}
