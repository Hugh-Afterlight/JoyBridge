import SwiftUI

struct PermissionStatusView: View {
    @EnvironmentObject private var accessibilityPermissionManager: AccessibilityPermissionManager

    var body: some View {
        GroupBox("权限状态") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 14) {
                    Text("Accessibility 权限：")
                    Text(accessibilityPermissionManager.isTrusted ? "已授权" : "未授权")
                        .fontWeight(.semibold)
                        .foregroundStyle(accessibilityPermissionManager.isTrusted ? .green : .red)

                    Spacer()

                    Button {
                        accessibilityPermissionManager.requestPermissionAndOpenSettings()
                    } label: {
                        Label("请求授权/打开设置", systemImage: "gearshape")
                    }

                    Button {
                        accessibilityPermissionManager.refreshPermissionStatus()
                    } label: {
                        Label("重新检测权限", systemImage: "arrow.clockwise")
                    }
                }

                Text(accessibilityPermissionManager.lastCheckedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("当前 App 路径：\(accessibilityPermissionManager.currentAppPath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
