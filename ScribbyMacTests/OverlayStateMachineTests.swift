import XCTest
@testable import ScribbyMac

final class OverlayStateMachineTests: XCTestCase {
    func testStartsHiddenAndTogglesIntoDrawing() {
        var machine = OverlayStateMachine()
        XCTAssertEqual(machine.state, .hidden)
        machine.handle(.toggleDrawing(hasAnnotations: false))
        XCTAssertEqual(machine.state, .drawing)
    }

    func testLeavingDrawingUsesAnnotationPresence() {
        var withoutAnnotations = OverlayStateMachine(state: .drawing)
        withoutAnnotations.handle(.toggleDrawing(hasAnnotations: false))
        XCTAssertEqual(withoutAnnotations.state, .hidden)

        var withAnnotations = OverlayStateMachine(state: .drawing)
        withAnnotations.handle(.toggleDrawing(hasAnnotations: true))
        XCTAssertEqual(withAnnotations.state, .passThrough)
    }

    func testHideAndShowTransitions() {
        var machine = OverlayStateMachine(state: .passThrough)
        machine.handle(.hide)
        XCTAssertEqual(machine.state, .hidden)
        machine.handle(.show(hasAnnotations: true))
        XCTAssertEqual(machine.state, .passThrough)
        machine.handle(.show(hasAnnotations: false))
        XCTAssertEqual(machine.state, .hidden)
    }

    func testClearKeepsDrawingButHidesPassiveOverlay() {
        var drawing = OverlayStateMachine(state: .drawing)
        drawing.handle(.cleared(hasAnnotations: false))
        XCTAssertEqual(drawing.state, .drawing)

        var passive = OverlayStateMachine(state: .passThrough)
        passive.handle(.cleared(hasAnnotations: false))
        XCTAssertEqual(passive.state, .hidden)
    }
}
