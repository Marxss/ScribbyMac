import AppKit

@MainActor
final class ToolbarPanelController: NSWindowController {
    private let store: AnnotationStore
    private let onSelectTool: (DrawingTool) -> Void
    private let onUndo: () -> Void
    private let onClear: () -> Void
    private let onDone: () -> Void
    private var toolButtons: [NSButton] = []
    private var colorButtons: [NSButton] = []
    private var widthButtons: [NSButton] = []

    init(
        store: AnnotationStore,
        onSelectTool: @escaping (DrawingTool) -> Void,
        onUndo: @escaping () -> Void,
        onClear: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) {
        self.store = store
        self.onSelectTool = onSelectTool
        self.onUndo = onUndo
        self.onClear = onClear
        self.onDone = onDone

        let panel = NSPanel(
            contentRect: CGRect(x: 0, y: 0, width: 651, height: 54),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Activation can raise the key overlay window. Keep controls above its hit-test surface.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + 1)
        panel.title = "ScribbyMac 工具栏"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        super.init(window: panel)
        buildContent()
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(on screen: NSScreen) {
        refresh()
        guard let panel = window else { return }
        let frame = panel.frame
        let origin = CGPoint(
            x: screen.frame.midX - frame.width / 2,
            y: screen.visibleFrame.maxY - frame.height - 12
        )
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func refresh() {
        for (index, button) in toolButtons.enumerated() {
            button.state = DrawingTool.allCases[index] == store.selectedTool ? .on : .off
        }
        for (index, button) in colorButtons.enumerated() {
            let isSelected = AnnotationColor.allCases[index] == store.selectedColor
            button.state = isSelected ? .on : .off
            button.layer?.borderWidth = isSelected ? 3 : 1
            button.layer?.borderColor = isSelected ? NSColor.controlAccentColor.cgColor : NSColor.separatorColor.cgColor
        }
        for (index, button) in widthButtons.enumerated() {
            if store.selectedTool == .text {
                let size = TextSize.allCases[index]
                button.title = String(Int(size.rawValue))
                button.toolTip = "字号 " + button.title
                button.state = size == store.selectedTextSize ? .on : .off
            } else {
                let width = StrokeWidth.allCases[index]
                button.title = String(Int(width.rawValue))
                button.toolTip = "线宽 " + button.title
                button.state = width == store.selectedStrokeWidth ? .on : .off
            }
        }
    }

    private func buildContent() {
        guard let panel = window else { return }
        let background = NSVisualEffectView(frame: panel.contentLayoutRect)
        background.material = .hudWindow
        background.state = .active
        background.blendingMode = .behindWindow
        background.wantsLayer = true
        background.layer?.cornerRadius = 12

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 7
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            stack.topAnchor.constraint(equalTo: background.topAnchor),
            stack.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])

        let symbols = ["scribble", "arrow.up.right", "rectangle", "textformat"]
        let tooltips = ["自由绘制", "箭头", "矩形", "文字"]
        for index in DrawingTool.allCases.indices {
            let button = symbolButton(symbols[index], tooltip: tooltips[index], action: #selector(selectTool(_:)))
            button.setButtonType(.pushOnPushOff)
            button.tag = index
            toolButtons.append(button)
            stack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(separator())

        for (index, color) in AnnotationColor.allCases.enumerated() {
            let button = NSButton(frame: CGRect(x: 0, y: 0, width: 26, height: 26))
            button.tag = index
            button.title = ""
            button.isBordered = false
            button.refusesFirstResponder = true
            button.wantsLayer = true
            button.layer?.cornerRadius = 11
            button.layer?.backgroundColor = color.nsColor.cgColor
            button.target = self
            button.action = #selector(selectColor(_:))
            button.widthAnchor.constraint(equalToConstant: 24).isActive = true
            button.heightAnchor.constraint(equalToConstant: 24).isActive = true
            colorButtons.append(button)
            stack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(separator())

        for (index, width) in StrokeWidth.allCases.enumerated() {
            let button = NSButton(title: String(Int(width.rawValue)), target: self, action: #selector(selectWidth(_:)))
            button.tag = index
            button.bezelStyle = .texturedRounded
            button.setButtonType(.pushOnPushOff)
            button.refusesFirstResponder = true
            button.toolTip = "线宽 " + String(Int(width.rawValue))
            widthButtons.append(button)
            stack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(separator())
        stack.addArrangedSubview(symbolButton("arrow.uturn.backward", tooltip: "撤销", action: #selector(undo)))
        stack.addArrangedSubview(symbolButton("trash", tooltip: "清空", action: #selector(clear)))
        stack.addArrangedSubview(symbolButton("checkmark", tooltip: "完成", action: #selector(done)))
        panel.contentView = background
    }

    private func symbolButton(_ symbol: String, tooltip: String, action: Selector) -> NSButton {
        let button = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip) ?? NSImage(), target: self, action: action)
        button.bezelStyle = .texturedRounded
        button.refusesFirstResponder = true
        button.imagePosition = .imageOnly
        button.toolTip = tooltip
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        return button
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        box.heightAnchor.constraint(equalToConstant: 28).isActive = true
        box.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return box
    }

    @objc private func selectTool(_ sender: NSButton) {
        guard DrawingTool.allCases.indices.contains(sender.tag) else { return }
        onSelectTool(DrawingTool.allCases[sender.tag])
        refresh()
    }

    @objc private func selectColor(_ sender: NSButton) {
        guard AnnotationColor.allCases.indices.contains(sender.tag) else { return }
        store.select(color: AnnotationColor.allCases[sender.tag])
        refresh()
    }

    @objc private func selectWidth(_ sender: NSButton) {
        guard StrokeWidth.allCases.indices.contains(sender.tag) else { return }
        if store.selectedTool == .text {
            store.select(textSize: TextSize.allCases[sender.tag])
        } else {
            store.select(strokeWidth: StrokeWidth.allCases[sender.tag])
        }
        refresh()
    }

    @objc private func undo() { onUndo() }
    @objc private func clear() { onClear() }
    @objc private func done() { onDone() }
}
