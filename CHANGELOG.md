# Changelog

## v0.2.0 - 2026-05-10

### English

This is the first friend-test update after the initial JoyBridge MVP.

Important notice for testers:

- This release is source code only. It is not a packaged `.dmg` or ready-to-install app yet.
- To test it, open `JoyBridge.xcodeproj` in Xcode, select the `JoyBridge` target, choose your own Apple Team or Personal Team in `Signing & Capabilities`, then run it on `My Mac`.
- After the app launches, grant JoyBridge Accessibility permission in System Settings > Privacy & Security > Accessibility. Without this permission, JoyBridge can detect controller input but cannot send keyboard events.
- If Accessibility was granted to an older Xcode build path and the app still shows as unauthorized, remove/re-add JoyBridge in Accessibility settings or run `tccutil reset Accessibility cc.afterlight.JoyBridge`, then launch the app again.
- Because there is no menu bar mode or login item yet, JoyBridge must be opened manually after each restart.
- The current build is best treated as a local test build for friends who are comfortable running an Xcode project.

Changed:

- Added modifier-only mappings, so a controller button can hold `Command`, `Option`, `Control`, or `Shift` without requiring a main key.
- Added `None/无` to the key picker for modifier-only mappings.
- Added real modifier key down/up events, so modifier-only bindings can be held and combined with another mapped button.
- Improved controller release handling so held modifiers are released when the mapped controller button is released, the mapping is edited, or the controller disconnects.
- Expanded controller input handling with `physicalInputProfile` diagnostics for better Joy-Con and compatible controller support.
- Added a left Joy-Con direction correction for single `Joy-Con (L)` use:
  - `Button Y -> DPad Right`
  - `Button X -> DPad Down`
  - `Button B -> DPad Up`
  - `Button A -> DPad Left`
- Improved logs for controller profiles, button values, DPad axes, mapping lookup, modifier holds, and keyboard event sending.
- Updated the README with modifier-only mapping instructions and troubleshooting notes.

Validation:

- Built successfully with Xcode/macOS Debug target.
- Manually tested Accessibility permission detection.
- Manually tested Joy-Con (L) direction input correction during local development.

Known limitations:

- No packaged `.dmg` release yet.
- Friends still need to open the project in Xcode, select their own Team, run the app, and grant Accessibility permission.
- No menu bar mode or login item support yet, so the app must be opened manually after restart.

### 中文

这是 JoyBridge 初始 MVP 之后的第一个朋友测试版更新。

测试者重要提醒：

- 当前版本只有源码，还不是已经打包好的 `.dmg` 或可直接安装的 App。
- 测试时需要用 Xcode 打开 `JoyBridge.xcodeproj`，选择 `JoyBridge` Target，在 `Signing & Capabilities` 里选择你自己的 Apple Team 或 Personal Team，然后选择 `My Mac` 运行。
- App 启动后，必须在 系统设置 > 隐私与安全性 > 辅助功能 中给 JoyBridge 授权。没有这个权限时，JoyBridge 可以识别手柄输入，但不能发送键盘事件。
- 如果以前给旧的 Xcode 构建路径授权过，但 App 仍显示未授权，可以在辅助功能设置中移除/重新添加 JoyBridge，或者运行 `tccutil reset Accessibility cc.afterlight.JoyBridge` 后重新启动 App。
- 当前还没有菜单栏常驻和开机自启，所以每次重启电脑后都需要手动打开 JoyBridge。
- 这个版本更适合作为“愿意用 Xcode 运行项目的朋友测试版”，不是面向普通用户的一键安装版。

本次更新：

- 新增纯修饰键映射，可以把手柄按钮映射成只按住 `Command`、`Option`、`Control` 或 `Shift`，不再强制选择主键。
- 在 Key 选择器中新增 `None/无`，用于配置纯修饰键。
- 新增真实修饰键按下/松开事件，让纯修饰键可以被按住，并和另一个手柄按钮组合使用。
- 改进释放逻辑：松开手柄按钮、编辑映射、断开控制器时，会释放已经按住的修饰键。
- 扩展了 `physicalInputProfile` 输入诊断，更好地支持 Joy-Con 和兼容手柄。
- 针对单只 `Joy-Con (L)` 新增方向键校正：
  - `Button Y -> DPad Right`
  - `Button X -> DPad Down`
  - `Button B -> DPad Up`
  - `Button A -> DPad Left`
- 改进日志输出，包含控制器 profile、按钮值、DPad 轴向、映射查找、修饰键保持和键盘事件发送。
- 更新 README，补充纯修饰键映射和排错说明。

验证结果：

- Xcode/macOS Debug 目标构建成功。
- 本地手动测试了 Accessibility 权限检测。
- 本地开发过程中手动测试了 `Joy-Con (L)` 方向键校正。

已知限制：

- 暂时没有打包 `.dmg`。
- 朋友仍然需要用 Xcode 打开项目，选择自己的 Team，运行 App，并授权 Accessibility 辅助功能权限。
- 暂时没有菜单栏常驻和开机自启，重启电脑后需要手动打开 App。
