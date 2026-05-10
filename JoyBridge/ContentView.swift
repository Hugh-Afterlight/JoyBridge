import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var accessibilityPermissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var controllerManager: ControllerManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("JoyBridge MVP")
                    .font(.largeTitle.bold())

                PermissionStatusView()
                ControllerStatusView()
                MappingListView()
                debugTips
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 940, minHeight: 720)
        .onAppear {
            accessibilityPermissionManager.refreshPermissionStatus(reason: "view appeared")
            controllerManager.scanControllers()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityPermissionManager.refreshPermissionStatusIfNeeded()
        }
    }

    private var debugTips: some View {
        GroupBox("调试提示") {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. 先连接 Joy-Con")
                Text("2. 授权 Accessibility")
                Text("3. 修改映射")
                Text("4. 按下手柄按钮测试")
                Text("5. 单只 Joy-Con 的 L/R/ZL/ZR 可能受 macOS GameController 限制，若日志没有 Button pressed，则当前版本无法映射")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
