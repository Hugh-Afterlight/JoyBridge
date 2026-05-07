import SwiftUI

@main
struct JoyBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var accessibilityPermissionManager: AccessibilityPermissionManager
    @StateObject private var mappingManager: MappingManager
    @StateObject private var controllerManager: ControllerManager

    init() {
        print("App started")

        let accessibilityPermissionManager = AccessibilityPermissionManager()
        let mappingManager = MappingManager(accessibilityPermissionManager: accessibilityPermissionManager)
        let controllerManager = ControllerManager(mappingManager: mappingManager)

        _accessibilityPermissionManager = StateObject(wrappedValue: accessibilityPermissionManager)
        _mappingManager = StateObject(wrappedValue: mappingManager)
        _controllerManager = StateObject(wrappedValue: controllerManager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(accessibilityPermissionManager)
                .environmentObject(mappingManager)
                .environmentObject(controllerManager)
        }
        .windowStyle(.titleBar)
    }
}
