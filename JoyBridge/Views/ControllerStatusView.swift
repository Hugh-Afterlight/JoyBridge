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
                    Text("最近按键：")
                    Text(controllerManager.latestPressedButton?.displayName ?? "无")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
