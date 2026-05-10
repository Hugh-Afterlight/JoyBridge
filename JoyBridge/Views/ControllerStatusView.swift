import SwiftUI

struct ControllerStatusView: View {
    @EnvironmentObject private var controllerManager: ControllerManager

    var body: some View {
        GroupBox("控制器状态") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("当前控制器：")
                    Text(controllerManager.connectedControllerName ?? "未连接")
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        controllerManager.scanControllers()
                    } label: {
                        Label("重新检测控制器", systemImage: "gamecontroller")
                    }
                }

                HStack {
                    Text("目标控制器：")
                    Picker("", selection: targetSelection) {
                        Text("自动选择第一个")
                            .tag(ControllerManager.automaticTargetID)

                        ForEach(controllerManager.availableControllers) { controller in
                            Text(controller.displayName)
                                .tag(controller.id)
                        }

                        if
                            let selectedID = controllerManager.selectedTargetControllerID,
                            let selectedName = controllerManager.selectedTargetControllerName,
                            !controllerManager.availableControllers.contains(where: { $0.id == selectedID })
                        {
                            Text("\(selectedName)（未连接）")
                                .tag(selectedID)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 320)

                    Button {
                        controllerManager.lockCurrentControllerAsTarget()
                    } label: {
                        Label("锁定当前", systemImage: "lock")
                    }
                    .disabled(!controllerManager.isControllerConnected)

                    if controllerManager.isTargetControllerSelected {
                        Button {
                            controllerManager.selectTargetController(id: nil)
                        } label: {
                            Label("清除目标", systemImage: "xmark.circle")
                        }
                    }
                }

                targetStatusText

                HStack {
                    Text("最近按键：")
                    Text(controllerManager.latestPressedButton?.displayName ?? "无")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var targetSelection: Binding<String> {
        Binding(
            get: {
                controllerManager.selectedTargetControllerID ?? ControllerManager.automaticTargetID
            },
            set: { newValue in
                if newValue == ControllerManager.automaticTargetID {
                    controllerManager.selectTargetController(id: nil)
                } else {
                    controllerManager.selectTargetController(id: newValue)
                }
            }
        )
    }

    @ViewBuilder
    private var targetStatusText: some View {
        if controllerManager.isTargetControllerSelected {
            if controllerManager.isSelectedTargetConnected {
                Text("目标状态：已锁定，只响应这个控制器")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("目标状态：目标控制器未连接，JoyBridge 不会响应其他手柄")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } else {
            Text("目标状态：自动选择第一个已连接控制器。建议测试稳定后点击“锁定当前”。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
