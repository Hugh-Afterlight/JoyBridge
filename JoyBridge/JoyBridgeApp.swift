import AppKit
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
        appDelegate.configure(mappingManager: mappingManager)
    }

    var body: some Scene {
        WindowGroup("JoyBridge", id: "main") {
            ContentView()
                .environmentObject(accessibilityPermissionManager)
                .environmentObject(mappingManager)
                .environmentObject(controllerManager)
        }
        .windowStyle(.titleBar)

        MenuBarExtra("JoyBridge", systemImage: "gamecontroller") {
            JoyBridgeMenuBarView()
                .environmentObject(accessibilityPermissionManager)
                .environmentObject(mappingManager)
                .environmentObject(controllerManager)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct JoyBridgeMenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var accessibilityPermissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var mappingManager: MappingManager
    @EnvironmentObject private var controllerManager: ControllerManager

    var body: some View {
        Text("监听状态：\(controllerManager.isControllerConnected ? "运行中" : "等待控制器")")
        Text("当前控制器：\(controllerManager.connectedControllerName ?? "未连接")")
        Text("辅助功能：\(accessibilityPermissionManager.isTrusted ? "已授权" : "未授权")")

        if let latestPressedButton = controllerManager.latestPressedButton {
            Text("最近按键：\(latestPressedButton.displayName)")
        }

        Divider()

        Button {
            showMainWindow()
        } label: {
            Label("显示 JoyBridge", systemImage: "macwindow")
        }

        Button {
            controllerManager.scanControllers()
        } label: {
            Label("重新检测控制器", systemImage: "gamecontroller")
        }

        if accessibilityPermissionManager.isTrusted {
            Button {
                accessibilityPermissionManager.refreshPermissionStatus(reason: "menu bar")
            } label: {
                Label("重新检测权限", systemImage: "arrow.clockwise")
            }
        } else {
            Button {
                accessibilityPermissionManager.requestPermissionAndOpenSettings()
            } label: {
                Label("请求授权/打开设置", systemImage: "gear")
            }
        }

        Divider()

        Button {
            mappingManager.releaseAllHeldModifiers()
            NSApp.terminate(nil)
        } label: {
            Label("退出 JoyBridge", systemImage: "power")
        }
    }

    private func showMainWindow() {
        if let window = NSApp.windows.first(where: { $0.title == "JoyBridge" }) {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }

            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
