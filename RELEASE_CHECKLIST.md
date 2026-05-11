# JoyBridge Release Checklist

This document explains the path from the current local friend-test builds to a future public macOS release.

JoyBridge is currently distributed as a local test `.zip`. A public macOS release needs a different signing and notarization process.

## Current Status

- Current test version: `v0.10.0`
- Bundle identifier: `cc.afterlight.JoyBridge`
- Local friend-test package: supported
- Developer ID public distribution: not ready yet
- Apple notarization: not performed yet
- App Store release: out of scope for the current MVP

## What v0.10.0 Uses From This Checklist

- A release-readiness checker: `Scripts/check-release-readiness.sh`
- Release-only Hardened Runtime project setting
- A clear public-release checklist for Developer ID and notarization
- Documentation links to Apple official release guidance

The checker is intentionally safe. It does not upload the app, does not call Apple notarization services, and does not store credentials.

## Run The Readiness Check

```sh
Scripts/check-release-readiness.sh v0.10.0
```

To also inspect a built or installed app bundle:

```sh
Scripts/check-release-readiness.sh v0.10.0 /Applications/JoyBridge.app
```

Strict mode exits with a non-zero status when warnings are found:

```sh
Scripts/check-release-readiness.sh --strict v0.10.0
```

Expected warnings before a real public release:

- Developer ID Application certificate may be missing.
- `JOYBRIDGE_NOTARY_PROFILE` may be missing.
- Git tag may not match until the version tag is created.
- Local test apps may be ad-hoc signed, not Gatekeeper accepted, and not stapled.

## Requirements For A Public Developer ID Release

Before JoyBridge can be distributed publicly outside the App Store, the release machine needs:

- An active Apple Developer Program membership.
- A `Developer ID Application` certificate in Keychain Access.
- Xcode command line tools with `notarytool` and `stapler`.
- Hardened Runtime enabled for the signed app.
- A stored `notarytool` keychain profile or equivalent App Store Connect API credentials.
- A clean git worktree and a version tag matching the package version.

Official Apple references:

- [Developer ID](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

## Recommended Public Release Flow

1. Confirm the current local test build works.
2. Update `AppInfo.currentTestVersion`, `MARKETING_VERSION`, `README.md`, and `CHANGELOG.md`.
3. Commit all intended changes.
4. Tag the commit, for example `v1.0.0`.
5. Run:

```sh
Scripts/check-release-readiness.sh --strict v1.0.0
```

6. Build an archive or Release app using Developer ID signing.
7. Verify the app signature.
8. Submit the signed app or distribution archive with `xcrun notarytool submit`.
9. Wait for notarization to succeed.
10. Staple the notarization ticket with `xcrun stapler staple`.
11. Verify Gatekeeper with `spctl -a -vv`.
12. Upload only the notarized package to GitHub Releases.

Do not publish a public release from a dirty worktree.

## Credential Safety

Do not commit Apple ID passwords, app-specific passwords, App Store Connect API keys, private keys, or keychain profile names that reveal private account details.

Use a local keychain profile for notarization credentials. For example, after credentials are configured locally, the shell can point JoyBridge scripts at the profile name:

```sh
export JOYBRIDGE_NOTARY_PROFILE="JoyBridgeNotary"
```

The readiness script only checks whether this environment variable is set. It does not validate the credential with Apple.

## 中文说明

这个文件说明 JoyBridge 从“本地朋友测试包”走向“公开 macOS 安装包”需要做什么。

当前 JoyBridge 仍然是本地测试 `.zip`。真正公开分发时，需要 Developer ID 签名和 Apple 公证。

### 当前状态

- 当前测试版本：`v0.10.0`
- Bundle identifier：`cc.afterlight.JoyBridge`
- 本地朋友测试包：支持
- Developer ID 公开分发：尚未完成
- Apple 公证：尚未执行
- App Store 发布：不属于当前 MVP 范围

### v0.10.0 如何使用这份清单

- 发布准备检查脚本：`Scripts/check-release-readiness.sh`
- Release 配置启用 Hardened Runtime
- Developer ID 和公证流程说明
- Apple 官方发布说明链接

这个检查脚本是安全的：它不会上传 App，不会调用 Apple 公证服务，也不会保存任何密码或密钥。

### 运行检查

```sh
Scripts/check-release-readiness.sh v0.10.0
```

如果还想检查已经构建或安装的 App bundle：

```sh
Scripts/check-release-readiness.sh v0.10.0 /Applications/JoyBridge.app
```

严格模式会在发现警告时返回失败：

```sh
Scripts/check-release-readiness.sh --strict v0.10.0
```

真正公开发布前，常见警告包括：

- 机器上还没有 `Developer ID Application` 证书。
- 当前 shell 没有设置 `JOYBRIDGE_NOTARY_PROFILE`。
- 还没有创建和版本匹配的 git tag。
- 本地测试 App 可能是 ad-hoc 签名、未被 Gatekeeper 接受、也没有附加公证票据。

### 公开 Developer ID 发布需要什么

公开分发前，发布机器需要：

- 有效的 Apple Developer Program 会员资格。
- Keychain 中有 `Developer ID Application` 证书。
- Xcode 命令行工具中有 `notarytool` 和 `stapler`。
- App 开启 Hardened Runtime。
- 本机已配置 `notarytool` keychain profile 或等价的 App Store Connect API 凭证。
- git 工作区是 clean，并且 tag 与打包版本一致。

### 建议发布流程

1. 先确认当前本地测试包可用。
2. 更新 `AppInfo.currentTestVersion`、`MARKETING_VERSION`、`README.md` 和 `CHANGELOG.md`。
3. 提交所有目标改动。
4. 创建版本 tag，例如 `v1.0.0`。
5. 运行：

```sh
Scripts/check-release-readiness.sh --strict v1.0.0
```

6. 使用 Developer ID 签名构建 Release App。
7. 验证签名。
8. 使用 `xcrun notarytool submit` 提交公证。
9. 等待公证成功。
10. 使用 `xcrun stapler staple` 附加公证票据。
11. 使用 `spctl -a -vv` 验证 Gatekeeper。
12. 只把已公证的包上传到 GitHub Releases。

不要从 dirty worktree 发布公开版本。

### 凭证安全

不要把 Apple ID 密码、App 专用密码、App Store Connect API key、私钥或会暴露个人账号信息的 keychain profile 名称提交进仓库。

建议在本机 keychain 中保存公证凭证。配置后，可以在 shell 中指定 profile 名称：

```sh
export JOYBRIDGE_NOTARY_PROFILE="JoyBridgeNotary"
```

当前检查脚本只会检测这个环境变量是否存在，不会联网验证凭证。
