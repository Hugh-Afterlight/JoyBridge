# JoyBridge

JoyBridge is a native macOS productivity tool that maps Nintendo Joy-Con, Switch Pro Controller, and compatible Bluetooth controller buttons to keyboard input.

It is not a game utility. The goal is simple: turn controller buttons into customizable macOS keyboard shortcuts.

## Current Test Version

Latest shared test version: `v0.7.0` / `2026-05-11`

This version adds an in-app readiness check panel, visible version information, clearer menu bar status, and a copyable diagnostic summary for friend testing. This is still not a notarized public release. See [CHANGELOG.md](CHANGELOG.md) for details.

## MVP Features

- Native macOS app built with Swift, SwiftUI, and AppKit
- Controller input through `GameController.framework`
- Keyboard event simulation through CoreGraphics `CGEvent`
- Accessibility permission detection and shortcut to System Settings
- Custom button-to-key mappings stored in `UserDefaults`
- Single-key shortcuts, modifier-only bindings, and modifier combinations such as `Command + C` or `Command + Shift + S`
- Debounced controller input so holding a button does not repeatedly fire
- Target controller selection and locking, so other connected controllers do not trigger mappings
- Menu bar item for checking status, reopening JoyBridge, rescanning controllers, checking Accessibility permission, and quitting the app
- Global pause/resume switch for temporarily disabling all keyboard output
- Readiness check panel for Accessibility, controller connection, target lock, and mapping output status
- Copyable diagnostic summary for easier friend-test feedback
- Local packaging script for creating friend-test `.zip` builds
- Package source summary with git commit, tag, and clean/dirty status in `READ-ME-FIRST.txt`
- Controller status, latest pressed button, and editable mapping list in the UI

## Supported Controller Inputs

- A
- B
- X
- Y
- Left Shoulder
- Right Shoulder
- Left Trigger
- Right Trigger
- DPad Up
- DPad Down
- DPad Left
- DPad Right

Note: these inputs are supported when Apple's `GameController.framework` exposes them for the connected controller. In current friend testing, connecting both left and right Joy-Cons at the same time allows DPad, `A/B/X/Y`, and `L/R/ZL/ZR` to work. When using only a single `Joy-Con (L)` or single `Joy-Con (R)`, the face/direction buttons work, but `L/R/ZL/ZR` may not report value changes.

## Default Mappings

| Controller Button | Keyboard Action |
| --- | --- |
| A | Space |
| B | Escape |
| X | Command + C |
| Y | Command + V |
| Left Shoulder | Command + Left Arrow |
| Right Shoulder | Command + Right Arrow |
| Left Trigger | Page Up |
| Right Trigger | Page Down |
| DPad Up | Up Arrow |
| DPad Down | Down Arrow |
| DPad Left | Left Arrow |
| DPad Right | Right Arrow |

## Requirements

- macOS 13 or later
- Xcode 16 or later recommended
- Apple Silicon Mac recommended for the current MVP
- A Nintendo Joy-Con, Switch Pro Controller, or compatible Bluetooth controller
- Accessibility permission granted to JoyBridge

## Run Locally

1. Clone the repository.
2. Open `JoyBridge.xcodeproj` in Xcode.
3. Select the `JoyBridge` target.
4. In `Signing & Capabilities`, choose your Apple Developer team or Personal Team.
5. Run the app on `My Mac`.
6. In JoyBridge, click `请求授权/打开设置`.
7. Enable JoyBridge in System Settings > Privacy & Security > Accessibility.
8. Return to JoyBridge and click `重新检测权限`.

For local development, App Sandbox is currently disabled to keep Accessibility and keyboard event testing straightforward.

If macOS still reports that Accessibility is missing after you grant permission, reset the permission record and run the app again:

```sh
tccutil reset Accessibility cc.afterlight.JoyBridge
```

## Create a Local Test Package

After the app works from Xcode, you can create a local friend-test package:

```sh
Scripts/package-local-release.sh v0.7.0
```

The script builds the Release app and writes the package to:

```text
dist/JoyBridge-v0.7.0-local-test.zip
```

Important notes:

- This package is for local friend testing only.
- It is signed with Apple Development for testing, not Developer ID for public distribution.
- It is not notarized by Apple yet, so macOS may show a security warning when opening it after download.
- Friends may need to right-click JoyBridge and choose Open, or approve it in System Settings > Privacy & Security.
- Recommended order: unzip the package, move `JoyBridge.app` to `/Applications`, open it, then grant Accessibility permission.
- Accessibility permission must be granted to the installed copy of JoyBridge. If an older Xcode build was authorized before, remove and re-add JoyBridge in Accessibility settings.
- `spctl` may report `rejected` or an internal code-signing error for this local package. That means it is not a notarized public release.
- `READ-ME-FIRST.txt` includes the git commit, tag, and whether the worktree was clean or dirty when packaged.
- The package is not committed to Git. `dist/` is ignored on purpose.

### If macOS Blocks JoyBridge

If you see a dialog like `Apple cannot verify JoyBridge`, do not move it to Trash if you trust this local test build.

Recommended path:

1. Click Done in the warning dialog.
2. Open System Settings > Privacy & Security.
3. Scroll to Security.
4. Click Open Anyway for JoyBridge.
5. Enter your Mac login password if asked.
6. Open JoyBridge again.

Apple usually shows the Open Anyway button for about one hour after you try to open the app.

Local tester fallback:

```sh
xattr -dr com.apple.quarantine /Applications/JoyBridge.app
```

Only use this fallback for a JoyBridge build you trust. It removes macOS's download quarantine flag for this app.

## Testing

1. Pair a Joy-Con or Switch Pro Controller in macOS Bluetooth settings.
2. Open JoyBridge and click `重新检测控制器`.
3. Confirm that the `运行检查` panel shows the current version and the next required step.
4. Confirm that the controller name appears.
5. Click `锁定当前` to save the current controller as the target controller.
6. Press controller buttons and confirm `最近按键` updates.
7. Open TextEdit or another text field.
8. Press `A` to test Space.
9. Select text and press `X` / `Y` to test copy and paste.
10. Change a mapping in the list and confirm the new action works. Set the Key picker to `None/无` when you want a modifier-only binding such as `Control`.
11. Hold a controller button and confirm it does not continuously repeat.
12. Release and press again to confirm it fires once more.
13. Close the main JoyBridge window and confirm JoyBridge remains in the menu bar.
14. Use the JoyBridge menu bar item to pause/resume mappings, check status, reopen the window, rescan controllers, check Accessibility permission, or quit the app.
15. Click `暂停映射`, press controller buttons, and confirm `最近按键` still updates but no keyboard input is sent.
16. Click `启用映射` and confirm mappings work again.
17. Click `复制诊断信息` and confirm a readable summary is copied for feedback.

After a target controller is locked, JoyBridge should only respond to that saved controller. If the target controller is not connected, JoyBridge should not automatically switch to another Bluetooth controller.

For Joy-Con testing, connecting both left and right Joy-Cons at the same time is recommended. Confirm the Xcode console shows `Button pressed`, `Mapping found`, and `Keyboard event sent`. If `L/R/ZL/ZR` do not print `Button pressed` when only one Joy-Con is connected, macOS is not exposing those physical buttons through `GameController.framework` for that single-controller mode.

Menu bar note: menu bar mode only keeps JoyBridge running after the main window is closed. It does not start JoyBridge automatically after a Mac restart yet. Open JoyBridge manually after restart, then quit it from the menu bar item when you are done testing.

Pause note: pausing mappings only stops keyboard output. Controller detection, latest pressed button display, and target controller locking continue to work. The pause state is saved and restored on next launch.

## Current MVP Scope

JoyBridge currently focuses only on custom controller-button-to-keyboard mappings, including single keys, modifier-only bindings, and key combinations.

Not included in the first version:

- Motion mouse
- Stick mouse control
- Stick scrolling
- Left/right Joy-Con merging
- Per-app profiles
- Cloud sync or iCloud sync
- Login item support
- Auto update
- App Store packaging
- Plugin system
- Complex shortcut recorder
- Electron, Tauri, Python, or Node.js implementation

## Project Structure

```text
JoyBridge/
  JoyBridgeApp.swift
  ContentView.swift
  AppDelegate.swift

  Managers/
    ControllerManager.swift
    MappingManager.swift
    AccessibilityPermissionManager.swift

  Models/
    ControllerButton.swift
    KeyboardKey.swift
    KeyModifier.swift
    KeyMapping.swift
    MappingAction.swift

  Utilities/
    KeyboardEventSender.swift

  Views/
    MappingListView.swift
    MappingRowView.swift
    PermissionStatusView.swift
    ControllerStatusView.swift

Scripts/
  package-local-release.sh
```

## Roadmap

- JSON import/export for mappings
- Multiple mapping profiles
- Better controller model diagnostics
- Universal build support
- Notarized Developer ID release packaging

---

# JoyBridge 中文说明

JoyBridge 是一个 macOS 原生生产力工具，用于把 Nintendo Joy-Con、Switch Pro Controller 和兼容蓝牙手柄的按钮映射成 macOS 键盘输入。

它不是游戏工具。它的目标很明确：让手柄按钮可以触发自定义键盘按键或快捷键。

## 当前测试版本

最新共享测试版本：`v0.7.0` / `2026-05-11`

这个版本新增 App 内运行检查面板、可见版本信息、更清楚的菜单栏状态和可复制诊断信息，方便朋友测试时判断当前是否可用。它还不是经过 Apple 公证的正式公开发行版。详细更新请看 [CHANGELOG.md](CHANGELOG.md)。

## MVP 功能

- 使用 Swift、SwiftUI、AppKit 构建的 macOS 原生 App
- 使用 `GameController.framework` 监听手柄输入
- 使用 CoreGraphics `CGEvent` 模拟键盘事件
- 检测 Accessibility 辅助功能权限，并提供跳转系统设置的按钮
- 使用 `UserDefaults` 保存自定义映射
- 支持单键、纯修饰键映射和组合键，例如 `Command + C`、`Command + Shift + S`
- 防止长按按钮时无限重复触发
- 支持选择并锁定目标控制器，避免其他已连接手柄触发映射
- 支持菜单栏入口，用于查看状态、重新打开 JoyBridge、重新检测控制器、检测辅助功能权限和退出 App
- 支持全局暂停/启用映射，用于临时停止所有键盘输出
- 支持运行检查面板，用于汇总辅助功能、控制器连接、目标锁定和映射输出状态
- 支持复制诊断信息，方便朋友测试时反馈问题
- 支持本地打包脚本，用于生成朋友测试版 `.zip`
- 测试包内的 `READ-ME-FIRST.txt` 会显示打包时的 git commit、tag 和工作区 clean/dirty 状态
- 界面显示控制器状态、最近按下按钮和可编辑映射列表

## 支持的手柄按钮

- A
- B
- X
- Y
- Left Shoulder
- Right Shoulder
- Left Trigger
- Right Trigger
- DPad Up
- DPad Down
- DPad Left
- DPad Right

注意：这些输入的前提是 Apple 的 `GameController.framework` 能从当前连接的控制器里暴露出对应按钮。当前朋友测试中，同时连接左右 Joy-Con 时，方向键、`A/B/X/Y` 和 `L/R/ZL/ZR` 都可以正常工作。只连接单只 `Joy-Con (L)` 或单只 `Joy-Con (R)` 时，面键/方向键可用，但 `L/R/ZL/ZR` 可能不会上报数值变化。

## 默认映射

| 手柄按钮 | 键盘动作 |
| --- | --- |
| A | Space |
| B | Escape |
| X | Command + C |
| Y | Command + V |
| Left Shoulder | Command + Left Arrow |
| Right Shoulder | Command + Right Arrow |
| Left Trigger | Page Up |
| Right Trigger | Page Down |
| DPad Up | Up Arrow |
| DPad Down | Down Arrow |
| DPad Left | Left Arrow |
| DPad Right | Right Arrow |

## 环境要求

- macOS 13 或更高版本
- 建议使用 Xcode 16 或更高版本
- 当前 MVP 优先面向 Apple Silicon
- Nintendo Joy-Con、Switch Pro Controller 或兼容蓝牙手柄
- 需要给 JoyBridge 授权 Accessibility 辅助功能权限

## 本地运行

1. 克隆仓库。
2. 用 Xcode 打开 `JoyBridge.xcodeproj`。
3. 选择 `JoyBridge` Target。
4. 在 `Signing & Capabilities` 中选择你的 Apple Developer Team 或 Personal Team。
5. 选择 `My Mac` 运行。
6. 在 JoyBridge 中点击 `请求授权/打开设置`。
7. 在 系统设置 > 隐私与安全性 > 辅助功能 中打开 JoyBridge。
8. 回到 JoyBridge，点击 `重新检测权限`。

本地开发阶段，App Sandbox 当前保持关闭，方便测试 Accessibility 和键盘事件发送。

如果已经授权但 App 仍显示未授权，可以重置 Accessibility 记录后重新运行：

```sh
tccutil reset Accessibility cc.afterlight.JoyBridge
```

## 生成本地测试包

确认 App 可以从 Xcode 正常运行后，可以生成一个给朋友测试的本地包：

```sh
Scripts/package-local-release.sh v0.7.0
```

脚本会构建 Release 版本，并把测试包输出到：

```text
dist/JoyBridge-v0.7.0-local-test.zip
```

重要提醒：

- 这个包只适合本地朋友测试。
- 它使用 Apple Development 测试签名，不是用于公开分发的 Developer ID 签名。
- 它还没有经过 Apple 公证，所以下载后打开时 macOS 可能会显示安全提醒。
- 朋友可能需要右键点击 JoyBridge 后选择打开，或在 系统设置 > 隐私与安全性 中手动允许。
- 建议顺序：先解压测试包，把 `JoyBridge.app` 移到“应用程序”，再打开，再授权辅助功能权限。
- 必须给安装后的这个 JoyBridge 授权辅助功能权限。如果以前授权的是 Xcode 构建版本，需要在辅助功能设置里移除并重新添加 JoyBridge。
- `spctl` 可能会对这个本地测试包显示 `rejected` 或代码签名内部错误。这表示它还不是经过 Apple 公证的正式公开发行版。
- `READ-ME-FIRST.txt` 会显示打包时的 git commit、tag，以及工作区当时是 clean 还是 dirty。
- 测试包不会提交到 Git。`dist/` 会被故意忽略。

### 如果 macOS 拦截 JoyBridge

如果看到类似 `Apple 无法验证 JoyBridge` 的弹窗，只要你确认这是可信的本地测试包，就不要点击移到废纸篓。

推荐处理方式：

1. 在弹窗里点击完成。
2. 打开 系统设置 > 隐私与安全性。
3. 滚动到安全性区域。
4. 找到 JoyBridge，点击仍要打开。
5. 如果系统要求，输入你的 Mac 登录密码。
6. 再次打开 JoyBridge。

Apple 通常只会在你尝试打开 App 后约一小时内显示仍要打开按钮。

本地测试者备用方式：

```sh
xattr -dr com.apple.quarantine /Applications/JoyBridge.app
```

只有在你确认这个 JoyBridge 测试包可信时，才使用这个备用命令。它会移除这个 App 的 macOS 下载隔离标记。

## 测试方法

1. 在 macOS 蓝牙设置中连接 Joy-Con 或 Switch Pro Controller。
2. 打开 JoyBridge，点击 `重新检测控制器`。
3. 确认 `运行检查` 面板显示当前版本和下一步需要处理的状态。
4. 确认界面显示控制器名称。
5. 点击 `锁定当前`，把当前控制器保存为目标控制器。
6. 按手柄按钮，确认 `最近按键` 更新。
7. 打开 TextEdit 或其他输入框。
8. 按 `A` 测试 Space。
9. 选中文本后按 `X` / `Y` 测试复制和粘贴。
10. 修改映射列表中的按键，确认新的映射生效。需要纯修饰键映射时，可以把 Key 选择器设为 `None/无`，例如只触发 `Control`。
11. 长按手柄按钮，确认不会连续疯狂触发。
12. 松开后再次按下，确认可以再次触发。
13. 关闭 JoyBridge 主窗口，确认 App 仍然留在菜单栏中。
14. 使用菜单栏里的 JoyBridge 暂停/启用映射、查看状态、重新打开窗口、重新检测控制器、检测辅助功能权限或退出 App。
15. 点击 `暂停映射`，按手柄按钮，确认 `最近按键` 仍会更新，但不会发送键盘输入。
16. 点击 `启用映射`，确认映射重新生效。
17. 点击 `复制诊断信息`，确认可以复制一段可读的问题反馈摘要。

锁定目标控制器后，JoyBridge 应该只响应这个已保存的控制器。如果目标控制器没有连接，JoyBridge 不应该自动切换到其他蓝牙手柄。

测试 Joy-Con 时，建议同时连接左右两个 Joy-Con。请以 Xcode 控制台中的 `Button pressed`、`Mapping found`、`Keyboard event sent` 为准。如果只连接单只 Joy-Con 时按 `L/R/ZL/ZR` 没有出现 `Button pressed`，说明 macOS 当前没有通过 `GameController.framework` 暴露这些实体按键。

菜单栏说明：菜单栏模式只表示关闭主窗口后 JoyBridge 继续运行。它还不会在 Mac 重启后自动启动。重启后仍需要手动打开 JoyBridge；测试结束时请从菜单栏里的 JoyBridge 选择退出。

暂停说明：暂停映射只会停止键盘输出。控制器检测、最近按键显示和目标控制器锁定仍会继续工作。暂停状态会保存，并在下次启动时恢复。

## 当前 MVP 范围

JoyBridge 第一版只专注于自定义“手柄按钮 -> 键盘单键 / 纯修饰键 / 键盘组合键”。

第一版暂不包含：

- 体感鼠标
- 摇杆控制鼠标
- 摇杆滚动
- 左右 Joy-Con 合并
- 按不同 App 自动切换配置
- 云同步或 iCloud 同步
- 登录项开机自启
- 自动更新
- App Store 打包发布
- 插件系统
- 复杂快捷键录制器
- Electron、Tauri、Python 或 Node.js 方案

## 项目结构

```text
JoyBridge/
  JoyBridgeApp.swift
  ContentView.swift
  AppDelegate.swift

  Managers/
    ControllerManager.swift
    MappingManager.swift
    AccessibilityPermissionManager.swift

  Models/
    ControllerButton.swift
    KeyboardKey.swift
    KeyModifier.swift
    KeyMapping.swift
    MappingAction.swift

  Utilities/
    KeyboardEventSender.swift

  Views/
    MappingListView.swift
    MappingRowView.swift
    PermissionStatusView.swift
    ControllerStatusView.swift

Scripts/
  package-local-release.sh
```

## 后续方向

- 映射 JSON 导入/导出
- 多配置文件
- 更完善的控制器型号诊断
- Universal 构建
- 经过 Apple 公证的 Developer ID 正式发布包
