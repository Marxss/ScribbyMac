import XCTest
@testable import ScribbyMac

final class MenuPresentationTests: XCTestCase {
    func testDrawingStateUsesFinishTitle() {
        let presentation = MenuPresentation.make(state: .drawing, hasAnnotations: false)
        XCTAssertEqual(presentation.drawingTitle, "结束绘图")
        XCTAssertFalse(presentation.canToggleVisibility)
        XCTAssertFalse(presentation.canClear)
    }

    func testPassiveStateCanHideAndClearAnnotations() {
        let presentation = MenuPresentation.make(state: .passThrough, hasAnnotations: true)
        XCTAssertEqual(presentation.drawingTitle, "开始绘图")
        XCTAssertEqual(presentation.visibilityTitle, "隐藏标注")
        XCTAssertTrue(presentation.canToggleVisibility)
        XCTAssertTrue(presentation.canClear)
    }

    func testHiddenStateCanShowExistingAnnotations() {
        let presentation = MenuPresentation.make(state: .hidden, hasAnnotations: true)
        XCTAssertEqual(presentation.visibilityTitle, "显示标注")
        XCTAssertTrue(presentation.canToggleVisibility)
        XCTAssertTrue(presentation.canClear)
    }

    func testNoAnnotationsDisablesVisibilityAndClear() {
        let presentation = MenuPresentation.make(state: .hidden, hasAnnotations: false)
        XCTAssertFalse(presentation.canToggleVisibility)
        XCTAssertFalse(presentation.canClear)
    }
}
