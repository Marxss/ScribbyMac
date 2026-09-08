import AppKit

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private let presentation: () -> MenuPresentation
    private let canUndo: () -> Bool
    private let onToggleDrawing: () -> Void
    private let onToggleVisibility: () -> Void
    private let onUndo: () -> Void
    private let onClear: () -> Void

    private let drawingItem = NSMenuItem()
    private let visibilityItem = NSMenuItem()
    private let undoItem = NSMenuItem()
    private let clearItem = NSMenuItem()

    init(
        presentation: @escaping () -> MenuPresentation,
        canUndo: @escaping () -> Bool,
        onToggleDrawing: @escaping () -> Void,
        onToggleVisibility: @escaping () -> Void,
        onUndo: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) {
        self.presentation = presentation
        self.canUndo = canUndo
        self.onToggleDrawing = onToggleDrawing
        self.onToggleVisibility = onToggleVisibility
        self.onUndo = onUndo
        self.onClear = onClear
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureMenu()
        refresh()
    }

    func refresh() {
        let value = presentation()
        drawingItem.title = value.drawingTitle
        visibilityItem.title = value.visibilityTitle
        visibilityItem.isEnabled = value.canToggleVisibility
        undoItem.isEnabled = canUndo()
        clearItem.isEnabled = value.canClear
    }

    private func configureMenu() {
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "pencil.tip.crop.circle", accessibilityDescription: "ScribbyMac")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "ScribbyMac"
        }

        let menu = NSMenu()
        drawingItem.target = self
        drawingItem.action = #selector(toggleDrawing)
        drawingItem.keyEquivalent = "d"
        drawingItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(drawingItem)

        visibilityItem.target = self
        visibilityItem.action = #selector(toggleVisibility)
        menu.addItem(visibilityItem)
        menu.addItem(.separator())

        undoItem.title = "撤销"
        undoItem.target = self
        undoItem.action = #selector(undo)
        undoItem.keyEquivalent = "z"
        undoItem.keyEquivalentModifierMask = .command
        menu.addItem(undoItem)

        clearItem.title = "清空标注"
        clearItem.target = self
        clearItem.action = #selector(clear)
        menu.addItem(clearItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 ScribbyMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    @objc private func toggleDrawing() { onToggleDrawing() }
    @objc private func toggleVisibility() { onToggleVisibility() }
    @objc private func undo() { onUndo() }
    @objc private func clear() { onClear() }
}
