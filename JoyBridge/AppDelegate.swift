import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private weak var mappingManager: MappingManager?

    func configure(mappingManager: MappingManager) {
        self.mappingManager = mappingManager
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        print("Menu bar extra available")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Main window closed; JoyBridge remains available in the menu bar")
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else {
            return true
        }

        sender.windows.first(where: { $0.title == "JoyBridge" })?.makeKeyAndOrderFront(nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        mappingManager?.releaseAllHeldModifiers()
        print("App terminating; held modifiers released")
    }
}
