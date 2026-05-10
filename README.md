# JoyBridge

JoyBridge is a native macOS productivity tool that maps Nintendo Joy-Con, Switch Pro Controller, and compatible Bluetooth controller buttons to keyboard input.

It is not a game utility. The goal is simple: turn controller buttons into customizable macOS keyboard shortcuts.

## Current Test Version

Latest shared test version: `v0.2.0` / `2026-05-10`

This version adds modifier-only mappings, improves Joy-Con input handling, and includes a dedicated correction for single left Joy-Con direction buttons. Friend testing found that single Joy-Con shoulder/trigger buttons may not be exposed by Apple's `GameController.framework`. See [CHANGELOG.md](CHANGELOG.md) for details.

## MVP Features

- Native macOS app built with Swift, SwiftUI, and AppKit
- Controller input through `GameController.framework`
- Keyboard event simulation through CoreGraphics `CGEvent`
- Accessibility permission detection and shortcut to System Settings
- Custom button-to-key mappings stored in `UserDefaults`
- Single-key shortcuts, modifier-only bindings, and modifier combinations such as `Command + C` or `Command + Shift + S`
- Debounced controller input so holding a button does not repeatedly fire
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

Note: these inputs are supported when Apple's `GameController.framework` exposes them for the connected controller. In current friend testing, single `Joy-Con (L)` and single `Joy-Con (R)` expose the face/direction buttons, but `L/R/ZL/ZR` do not report value changes, so JoyBridge cannot map those shoulder/trigger buttons in single Joy-Con mode yet.

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
4. Press controller buttons and confirm `最近按键` updates.
5. Open TextEdit or another text field.
6. Press `A` to test Space.
7. Select text and press `X` / `Y` to test copy and paste.
8. Change a mapping in the list and confirm the new action works. Set the Key picker to `None/无` when you want a modifier-only binding such as `Control`.
9. Hold a controller button and confirm it does not continuously repeat.
10. Release and press again to confirm it fires once more.

For single Joy-Con testing, confirm the Xcode console shows `Button pressed`, `Mapping found`, and `Keyboard event sent`. If `L/R/ZL/ZR` do not print `Button pressed`, macOS is not exposing those physical buttons through `GameController.framework` for that connection mode.

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

最新共享测试版本：`v0.2.0` / `2026-05-10`

这个版本新增了纯修饰键映射，改进了 Joy-Con 输入识别，并针对单只左 Joy-Con 的方向键做了专用校正。朋友测试发现，单只 Joy-Con 的肩键/扳机键可能不会被 Apple 的 `GameController.framework` 暴露出来。详细更新请看 [CHANGELOG.md](CHANGELOG.md)。

## MVP 功能

- 使用 Swift、SwiftUI、AppKit 构建的 macOS 原生 App
- 使用 `GameController.framework` 监听手柄输入
- 使用 CoreGraphics `CGEvent` 模拟键盘事件
- 检测 Accessibility 辅助功能权限，并提供跳转系统设置的按钮
- 使用 `UserDefaults` 保存自定义映射
- 支持单键、纯修饰键映射和组合键，例如 `Command + C`、`Command + Shift + S`
- 防止长按按钮时无限重复触发
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

注意：这些输入的前提是 Apple 的 `GameController.framework` 能从当前连接的控制器里暴露出对应按钮。当前朋友测试中，单只 `Joy-Con (L)` 和单只 `Joy-Con (R)` 可以识别面键/方向键，但 `L/R/ZL/ZR` 不会上报数值变化，所以 JoyBridge 当前无法在单只 Joy-Con 模式下映射这些肩键/扳机键。

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
4. 按手柄按钮，确认 `最近按键` 更新。
5. 打开 TextEdit 或其他输入框。
6. 按 `A` 测试 Space。
7. 选中文本后按 `X` / `Y` 测试复制和粘贴。
8. 修改映射列表中的按键，确认新的映射生效。需要纯修饰键映射时，可以把 Key 选择器设为 `None/无`，例如只触发 `Control`。
9. 长按手柄按钮，确认不会连续疯狂触发。
10. 松开后再次按下，确认可以再次触发。

测试单只 Joy-Con 时，请以 Xcode 控制台中的 `Button pressed`、`Mapping found`、`Keyboard event sent` 为准。如果按 `L/R/ZL/ZR` 时没有出现 `Button pressed`，说明 macOS 当前没有通过 `GameController.framework` 暴露这些实体按键。

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

- 菜单栏常驻模式
- 映射 JSON 导入/导出
- 多配置文件
- 更完善的控制器型号诊断
- Universal 构建
- 更完整的发布打包流程
