import AppKit

enum AppConfiguration {
    static let minimumSystemMajor = 13
    static let globalHotKeyDisplay = "⌘⇧D"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
