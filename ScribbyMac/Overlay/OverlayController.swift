import AppKit
import OSLog

@MainActor
final class OverlayController {
    private let store: AnnotationStore
    private let canvas: DrawingCanvasView
    private var stateMachine = OverlayStateMachine()
    private var overlayWindow: OverlayWindow?
    private let logger = Logger(subsystem: "com.local.ScribbyMac", category: "overlay")

    var onPresentationChange: (() -> Void)?
    var state: OverlayState { stateMachine.state }
    var menuPresentation: MenuPresentation {
        .make(state: state, hasAnnotations: store.hasAnnotations)
    }

    private lazy var toolbar = ToolbarPanelController(
        store: store,
        onSelectTool: { [weak self] tool in
            self?.canvas.cancelPendingInteraction()
            self?.store.select(tool: tool)
        },
        onUndo: { [weak self] in self?.undo() },
        onClear: { [weak self] in self?.clearAnnotations() },
        onDone: { [weak self] in self?.toggleDrawing() }
    )

    init(store: AnnotationStore) {
        self.store = store
        canvas = DrawingCanvasView(store: store)
        store.onChange = { [weak self] in
            guard let self else { return }
            self.canvas.needsDisplay = true
            self.toolbar.refresh()
            self.onPresentationChange?()
        }
    }

    func toggleDrawing() {
        if state != .drawing, NSScreen.main == nil {
            logger.error("Cannot enter drawing mode because no main screen is available")
            return
        }
        if state == .drawing {
            canvas.cancelPendingInteraction()
        }
        stateMachine.handle(.toggleDrawing(hasAnnotations: store.hasAnnotations))
        applyState()
    }

    func toggleVisibility() {
        if state == .hidden {
            showAnnotations()
        } else if state == .passThrough {
            hideAnnotations()
        }
    }

    func hideAnnotations() {
        canvas.cancelPendingInteraction()
        stateMachine.handle(.hide)
        applyState()
    }

    func showAnnotations() {
        guard store.hasAnnotations, NSScreen.main != nil else { return }
        stateMachine.handle(.show(hasAnnotations: true))
        applyState()
    }

    func clearAnnotations() {
        store.clear()
        stateMachine.handle(.cleared(hasAnnotations: store.hasAnnotations))
        applyState()
    }

    func undo() {
        store.undo()
        stateMachine.handle(.cleared(hasAnnotations: store.hasAnnotations))
        applyState()
    }

    private func applyState() {
        switch state {
        case .drawing:
            guard let screen = NSScreen.main else { return }
            let window = ensureOverlayWindow(on: screen)
            window.ignoresMouseEvents = false
            canvas.borderVisible = true
            window.makeKeyAndOrderFront(nil)
            toolbar.show(on: screen)
        case .passThrough:
            guard let screen = NSScreen.main else {
                stateMachine.handle(.hide)
                applyState()
                return
            }
            let window = ensureOverlayWindow(on: screen)
            canvas.cancelPendingInteraction()
            canvas.borderVisible = false
            window.ignoresMouseEvents = true
            window.orderFrontRegardless()
            toolbar.hide()
        case .hidden:
            canvas.cancelPendingInteraction()
            canvas.borderVisible = false
            toolbar.hide()
            overlayWindow?.orderOut(nil)
        }
        onPresentationChange?()
    }

    private func ensureOverlayWindow(on screen: NSScreen) -> OverlayWindow {
        if let overlayWindow {
            overlayWindow.setFrame(screen.frame, display: true)
            return overlayWindow
        }
        let window = OverlayWindow(frame: screen.frame)
        canvas.frame = CGRect(origin: .zero, size: screen.frame.size)
        canvas.autoresizingMask = [.width, .height]
        window.contentView = canvas
        overlayWindow = window
        return window
    }
}
