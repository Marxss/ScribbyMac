import AppKit
import Carbon.HIToolbox

enum AppConfiguration {
    static let minimumSystemMajor = 13
    static let globalHotKeyDisplay = "⌘⇧D"
    static let hotKeyKeyCode = UInt32(kVK_ANSI_D)
    static let hotKeyModifiers = UInt32(cmdKey | shiftKey)
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: AnnotationStore?
    private var overlayController: OverlayController?
    private var statusMenuController: StatusMenuController?
    private var hotKeyController: GlobalHotKeyController?
    private var previouslyActiveApplication: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Unit-test hosts must not register a competing global hotkey or show modal alerts.
        guard NSClassFromString("XCTestCase") == nil else { return }

        let store = AnnotationStore()
        let overlayController = OverlayController(store: store)
        overlayController.onToggleDrawingRequested = { [weak self] in self?.toggleDrawing() }
        let statusMenuController = StatusMenuController(
            presentation: { [weak overlayController] in
                overlayController?.menuPresentation
                    ?? .make(state: .hidden, hasAnnotations: false)
            },
            canUndo: { [weak store] in store?.canUndo ?? false },
            onToggleDrawing: { [weak self] in self?.toggleDrawing() },
            onToggleVisibility: { [weak overlayController] in overlayController?.toggleVisibility() },
            onUndo: { [weak overlayController] in overlayController?.undo() },
            onClear: { [weak overlayController] in overlayController?.clearAnnotations() }
        )
        overlayController.onPresentationChange = { [weak statusMenuController] in
            statusMenuController?.refresh()
        }

        let hotKeyController = GlobalHotKeyController { [weak self] in
            self?.toggleDrawing()
        }
        do {
            try hotKeyController.register()
        } catch {
            showHotKeyRegistrationError(error)
        }

        self.store = store
        self.overlayController = overlayController
        self.statusMenuController = statusMenuController
        self.hotKeyController = hotKeyController
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController?.unregister()
    }

    private func toggleDrawing() {
        guard let overlayController else { return }
        let wasDrawing = overlayController.state == .drawing
        if !wasDrawing {
            previouslyActiveApplication = NSWorkspace.shared.frontmostApplication
        }

        overlayController.toggleDrawing()
        if overlayController.state == .drawing {
            if #available(macOS 14, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        } else if wasDrawing {
            previouslyActiveApplication?.activate(options: [])
            previouslyActiveApplication = nil
        }
    }

    private func showHotKeyRegistrationError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "无法注册全局快捷键 " + AppConfiguration.globalHotKeyDisplay
        alert.informativeText = error.localizedDescription + "\n仍可从菜单栏开始绘图。"
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}
