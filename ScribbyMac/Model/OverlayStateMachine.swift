enum OverlayState: Equatable {
    case hidden
    case passThrough
    case drawing
}

enum OverlayEvent {
    case toggleDrawing(hasAnnotations: Bool)
    case hide
    case show(hasAnnotations: Bool)
    case cleared(hasAnnotations: Bool)
}

struct OverlayStateMachine {
    private(set) var state: OverlayState

    init(state: OverlayState = .hidden) {
        self.state = state
    }

    mutating func handle(_ event: OverlayEvent) {
        switch event {
        case let .toggleDrawing(hasAnnotations):
            state = state == .drawing
                ? (hasAnnotations ? .passThrough : .hidden)
                : .drawing
        case .hide:
            state = .hidden
        case let .show(hasAnnotations):
            state = hasAnnotations ? .passThrough : .hidden
        case let .cleared(hasAnnotations):
            guard state != .drawing else { return }
            state = hasAnnotations ? .passThrough : .hidden
        }
    }
}
