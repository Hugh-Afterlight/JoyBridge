import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var accessibilityPermissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var mappingManager: MappingManager
    @EnvironmentObject private var controllerManager: ControllerManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("JoyBridge MVP")
                    .font(.largeTitle.bold())
                Text("\(AppInfo.currentTestVersion) · \(AppInfo.releaseDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ReadinessStatusView()
                PermissionStatusView()
                mappingStatusView
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

    private var mappingStatusView: some View {
        GroupBox("映射状态") {
            HStack {
                Text("当前映射：")
                Text(mappingManager.isMappingPaused ? "已暂停" : "已启用")
                    .fontWeight(.semibold)
                    .foregroundStyle(mappingManager.isMappingPaused ? .orange : .green)

                Spacer()

                Button {
                    mappingManager.toggleMappingPaused()
                } label: {
                    Label(
                        mappingManager.isMappingPaused ? "启用映射" : "暂停映射",
                        systemImage: mappingManager.isMappingPaused ? "play.circle" : "pause.circle"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var debugTips: some View {
        GroupBox("调试提示") {
            VStack(alignment: .leading, spacing: 8) {
                Text("1. 先连接 Joy-Con")
                Text("2. 授权辅助功能权限（Accessibility）")
                Text("3. 点击“锁定当前”，避免响应其他蓝牙手柄")
                Text("4. 修改映射")
                Text("5. 按下手柄按钮测试")
                Text("6. 建议同时连接左右 Joy-Con；单只 Joy-Con 的 L/R/ZL/ZR 可能受 macOS GameController 限制")
                Text("7. 关闭主窗口后，JoyBridge 会继续在菜单栏运行；需要完全退出时请使用菜单栏里的“退出 JoyBridge”")
                Text("8. 需要临时停用时，可以在主窗口或菜单栏点击“暂停映射”")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
