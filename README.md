# JoyBridge

JoyBridge is a native macOS productivity tool that maps Nintendo Joy-Con, Switch Pro Controller, and compatible Bluetooth controller buttons to keyboard input.

It is not a game utility. The goal is simple: turn controller buttons into customizable macOS keyboard shortcuts.

## Current Test Version

Latest shared test version: `v0.4.0` / `2026-05-10`

This version adds a simple menu bar mode. Closing the main window no longer quits JoyBridge, and the menu bar item can reopen the window, rescan controllers, or quit the app. It also keeps target controller locking and the Joy-Con pairing notes from previous test builds. See [CHANGELOG.md](CHANGELOG.md) for details.

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

## Testing

1. Pair a Joy-Con or Switch Pro Controller in macOS Bluetooth settings.
2. Open JoyBridge and click `重新检测控制器`.
3. Confirm that the controller name appears.
4. Click `锁定当前` to save the current controller as the target controller.
5. Press controller buttons and confirm `最近按键` updates.
6. Open TextEdit or another text field.
7. Press `A` to test Space.
8. Select text and press `X` / `Y` to test copy and paste.
9. Change a mapping in the list and confirm the new action works. Set the Key picker to `None/无` when you want a modifier-only binding such as `Control`.
10. Hold a controller button and confirm it does not continuously repeat.
11. Release and press again to confirm it fires once more.
12. Close the main JoyBridge window and confirm JoyBridge remains in the menu bar.
13. Use the JoyBridge menu bar item to check status, reopen the window, rescan controllers, check Accessibility permission, or quit the app.

After a target controller is locked, JoyBridge should only respond to that saved controller. If the target controller is not connected, JoyBridge should not automatically switch to another Bluetooth controller.

For Joy-Con testing, connecting both left and right Joy-Cons at the same time is recommended. Confirm the Xcode console shows `Button pressed`, `Mapping found`, and `Keyboard event sent`. If `L/R/ZL/ZR` do not print `Button pressed` when only one Joy-Con is connected, macOS is not exposing those physical buttons through `GameController.framework` for that single-controller mode.

Menu bar note: menu bar mode only keeps JoyBridge running after the main window is closed. It does not start JoyBridge automatically after a Mac restart yet. Open JoyBridge manually after restart, then quit it from the menu bar item when you are done testing.

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
```

## Roadmap

- Menu bar mode
- JSON import/export for mappings
- Multiple mapping profiles
- Better controller model diagnostics
- Universal build support
- More polished release packaging

---

# JoyBridge 中文说明

JoyBridge 是一个 macOS 原生生产力工具，用于把 Nintendo Joy-Con、Switch Pro Controller 和兼容蓝牙手柄的按钮映射成 macOS 键盘输入。

它不是游戏工具。它的目标很明确：让手柄按钮可以触发自定义键盘按键或快捷键。

## 当前测试版本

最新共享测试版本：`v0.4.0` / `2026-05-10`

这个版本新增了简单的菜单栏常驻模式。关闭主窗口后 JoyBridge 不会退出，可以通过菜单栏重新打开窗口、重新检测控制器或退出 App。同时保留之前测试版里的目标控制器锁定和 Joy-Con 连接方式说明。详细更新请看 [CHANGELOG.md](CHANGELOG.md)。

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

## 测试方法

1. 在 macOS 蓝牙设置中连接 Joy-Con 或 Switch Pro Controller。
2. 打开 JoyBridge，点击 `重新检测控制器`。
3. 确认界面显示控制器名称。
4. 点击 `锁定当前`，把当前控制器保存为目标控制器。
5. 按手柄按钮，确认 `最近按键` 更新。
6. 打开 TextEdit 或其他输入框。
7. 按 `A` 测试 Space。
8. 选中文本后按 `X` / `Y` 测试复制和粘贴。
9. 修改映射列表中的按键，确认新的映射生效。需要纯修饰键映射时，可以把 Key 选择器设为 `None/无`，例如只触发 `Control`。
10. 长按手柄按钮，确认不会连续疯狂触发。
11. 松开后再次按下，确认可以再次触发。
12. 关闭 JoyBridge 主窗口，确认 App 仍然留在菜单栏中。
13. 使用菜单栏里的 JoyBridge 查看状态、重新打开窗口、重新检测控制器、检测辅助功能权限或退出 App。

锁定目标控制器后，JoyBridge 应该只响应这个已保存的控制器。如果目标控制器没有连接，JoyBridge 不应该自动切换到其他蓝牙手柄。

测试 Joy-Con 时，建议同时连接左右两个 Joy-Con。请以 Xcode 控制台中的 `Button pressed`、`Mapping found`、`Keyboard event sent` 为准。如果只连接单只 Joy-Con 时按 `L/R/ZL/ZR` 没有出现 `Button pressed`，说明 macOS 当前没有通过 `GameController.framework` 暴露这些实体按键。

菜单栏说明：菜单栏模式只表示关闭主窗口后 JoyBridge 继续运行。它还不会在 Mac 重启后自动启动。重启后仍需要手动打开 JoyBridge；测试结束时请从菜单栏里的 JoyBridge 选择退出。

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
```

## 后续方向

- 映射 JSON 导入/导出
- 多配置文件
- 更完善的控制器型号诊断
- Universal 构建
- 更完整的发布打包流程
