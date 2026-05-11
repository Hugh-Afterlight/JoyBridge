import AppKit
import SwiftUI

struct ReadinessStatusView: View {
    @EnvironmentObject private var accessibilityPermissionManager: AccessibilityPermissionManager
    @EnvironmentObject private var mappingManager: MappingManager
    @EnvironmentObject private var controllerManager: ControllerManager
    @State private var didCopyDiagnosticSummary = false

    var body: some View {
        GroupBox("运行检查") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: readinessIconName)
                        .foregroundStyle(readinessColor)

                    Text(readinessTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(readinessColor)

                    Spacer()

                    Text("\(AppInfo.currentTestVersion) · 本地测试版")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                readinessRow(
                    title: "辅助功能",
                    value: accessibilityPermissionManager.isTrusted ? "已授权" : "需要授权",
                    color: accessibilityPermissionManager.isTrusted ? .green : .red
                )

                readinessRow(
                    title: "控制器",
                    value: controllerManager.connectedControllerName ?? "未连接",
                    color: controllerManager.isControllerConnected ? .green : .orange
                )

                readinessRow(
                    title: "目标控制器",
                    value: targetControllerStatus,
                    color: targetControllerColor
                )

                readinessRow(
                    title: "映射输出",
                    value: mappingManager.isMappingPaused ? "已暂停" : "已启用",
                    color: mappingManager.isMappingPaused ? .orange : .green
                )

                Text(readinessHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button {
                        copyDiagnosticSummary()
                    } label: {
                        Label("复制诊断信息", systemImage: "doc.on.doc")
                    }

                    if didCopyDiagnosticSummary {
                        Text("已复制")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private func readinessRow(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(title)：")
                .foregroundStyle(.secondary)

            Text(value)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var readinessTitle: String {
        if !accessibilityPermissionManager.isTrusted {
            return "需要授权辅助功能"
        }

        if !controllerManager.isControllerConnected {
            return "等待控制器"
        }

        if mappingManager.isMappingPaused {
            return "映射已暂停"
        }

        if !controllerManager.isTargetControllerSelected {
            return "可以测试，建议锁定目标控制器"
        }

        return "已准备好"
    }

    private var readinessHint: String {
        if !accessibilityPermissionManager.isTrusted {
            return "请先点击“请求授权/打开设置”，把当前安装位置的 JoyBridge 加到辅助功能权限里。"
        }

        if !controllerManager.isControllerConnected {
            return "请先连接 Joy-Con 或 Switch Pro Controller，然后点击“重新检测控制器”。"
        }

        if mappingManager.isMappingPaused {
            return "JoyBridge 正在监听手柄，但暂停了键盘输出。需要使用映射时请点击“启用映射”。"
        }

        if !controllerManager.isTargetControllerSelected {
            return "当前会自动选择第一个控制器。日常使用前建议点击“锁定当前”，避免响应其他蓝牙手柄。"
        }

        return "现在可以按手柄测试映射。需要临时停用时，可以从主窗口或菜单栏暂停映射。"
    }

    private var readinessIconName: String {
        if !accessibilityPermissionManager.isTrusted {
            return "exclamationmark.triangle"
        }

        if mappingManager.isMappingPaused {
            return "pause.circle"
        }

        if controllerManager.isControllerConnected {
            return "checkmark.circle"
        }

        return "gamecontroller"
    }

    private var readinessColor: Color {
        if !accessibilityPermissionManager.isTrusted {
            return .red
        }

        if mappingManager.isMappingPaused || !controllerManager.isControllerConnected {
            return .orange
        }

        return .green
    }

    private var targetControllerStatus: String {
        if controllerManager.isTargetControllerSelected {
            if controllerManager.isSelectedTargetConnected {
                return "已锁定"
            }

            return "已锁定，但目标未连接"
        }

        return "自动选择第一个"
    }

    private var targetControllerColor: Color {
        if controllerManager.isTargetControllerSelected {
            return controllerManager.isSelectedTargetConnected ? .green : .orange
        }

        return .secondary
    }

    private func copyDiagnosticSummary() {
        let summary = [
            "JoyBridge 诊断信息",
            "版本：\(AppInfo.currentTestVersion)",
            "Bundle ID：\(AppInfo.bundleIdentifier)",
            "App 路径：\(accessibilityPermissionManager.currentAppPath)",
            "辅助功能权限（Accessibility）：\(accessibilityPermissionManager.isTrusted ? "已授权" : "未授权")",
            "映射输出：\(mappingManager.isMappingPaused ? "已暂停" : "已启用")",
            "当前控制器：\(controllerManager.connectedControllerName ?? "未连接")",
            "目标控制器状态：\(targetControllerStatus)",
            "目标控制器名称：\(controllerManager.selectedTargetControllerName ?? "未设置")",
            "最近按键：\(controllerManager.latestPressedButton?.displayName ?? "无")",
            "反馈时请补充：你按了哪个手柄按钮、期望发生什么、实际发生了什么。"
        ].joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        didCopyDiagnosticSummary = true
    }
}
