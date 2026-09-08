import AppKit

final class OverlayWindow: NSWindow {
    init(frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle,
        ]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
