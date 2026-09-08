struct MenuPresentation: Equatable {
    let drawingTitle: String
    let visibilityTitle: String
    let canToggleVisibility: Bool
    let canClear: Bool

    static func make(state: OverlayState, hasAnnotations: Bool) -> MenuPresentation {
        MenuPresentation(
            drawingTitle: state == .drawing ? "结束绘图" : "开始绘图",
            visibilityTitle: state == .hidden ? "显示标注" : "隐藏标注",
            canToggleVisibility: hasAnnotations && state != .drawing,
            canClear: hasAnnotations
        )
    }
}
