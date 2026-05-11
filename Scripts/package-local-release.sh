#!/usr/bin/env bash

set -euo pipefail

VERSION="${1:-local}"
SAFE_VERSION="$(printf '%s' "$VERSION" | tr -c 'A-Za-z0-9._-' '-')"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$REPO_ROOT/JoyBridge.xcodeproj"
SCHEME="JoyBridge"
CONFIGURATION="Release"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-/private/tmp/JoyBridgePackageDerivedData}"
STAGING_DIR="/private/tmp/JoyBridgePackage-$SAFE_VERSION"
DIST_DIR="$REPO_ROOT/dist"
APP_NAME="JoyBridge.app"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
PACKAGE_BASENAME="JoyBridge-$SAFE_VERSION-local-test"
ZIP_PATH="$DIST_DIR/$PACKAGE_BASENAME.zip"
GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
GIT_TAG="$(git -C "$REPO_ROOT" describe --tags --exact-match HEAD 2>/dev/null || printf 'none')"
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=normal 2>/dev/null || true)" ]]; then
  GIT_STATUS="dirty"
else
  GIT_STATUS="clean"
fi

echo "==> JoyBridge local package"
echo "Version: $VERSION"
echo "Repo: $REPO_ROOT"
echo "Git commit: $GIT_COMMIT"
echo "Git tag: $GIT_TAG"
echo "Git status: $GIT_STATUS"
echo

if [[ -z "${DEVELOPER_DIR:-}" && -d "/Applications/Xcode.app/Contents/Developer" ]]; then
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

echo "Developer dir: ${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null || printf 'not found')}"
echo

mkdir -p "$DIST_DIR"
rm -rf "$STAGING_DIR"
rm -f "$ZIP_PATH"
mkdir -p "$STAGING_DIR"

echo "==> Building $CONFIGURATION app"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "ERROR: built app not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Preparing staging folder"
cp -R "$APP_PATH" "$STAGING_DIR/$APP_NAME"
cp "$REPO_ROOT/README.md" "$STAGING_DIR/README.md"
cp "$REPO_ROOT/CHANGELOG.md" "$STAGING_DIR/CHANGELOG.md"

{
  printf '%s\n' "JoyBridge local test package"
  printf '%s\n' "Version: $VERSION"
  printf '%s\n' "Git commit: $GIT_COMMIT"
  printf '%s\n' "Git tag: $GIT_TAG"
  printf '%s\n' "Git status when packaged: $GIT_STATUS"
  printf '\n'
  printf '%s\n' "Important:"
  printf '%s\n' "- This is a local friend-test build, not a notarized public release."
  printf '%s\n' "- It is signed by Xcode for local testing, not with Developer ID for public distribution."
  printf '%s\n' "- macOS may warn that the app cannot be verified because it is not notarized yet."
  printf '%s\n' "- Recommended order: move JoyBridge.app to /Applications first, then open it, then grant Accessibility permission."
  printf '%s\n' "- If macOS says Apple cannot verify JoyBridge, click Done, then open System Settings > Privacy & Security > Security and click Open Anyway."
  printf '%s\n' "- Apple usually shows Open Anyway for about one hour after you try to open the app."
  printf '%s\n' "- Local tester fallback, only for builds you trust: xattr -dr com.apple.quarantine /Applications/JoyBridge.app"
  printf '%s\n' "- Open the app manually after each restart. Login item autostart is not implemented yet."
  printf '%s\n' "- Grant Accessibility permission to this installed copy of JoyBridge before testing mappings."
  printf '%s\n' "- If an older Xcode build was authorized before, remove/re-add JoyBridge in Accessibility settings."
  printf '%s\n' "- Gatekeeper assessment may report rejected or an internal code-signing error for this local package."
  printf '\n'
  printf '%s\n' "中文说明："
  printf '%s\n' "- 这是本地朋友测试包，不是已经公证的正式公开发行版。"
  printf '%s\n' "- 它使用 Xcode 本地测试签名，不是用于公开分发的 Developer ID 签名。"
  printf '%s\n' "- macOS 可能提示无法验证 App，因为当前还没有做 Apple 公证。"
  printf '%s\n' "- 建议顺序：先把 JoyBridge.app 移到“应用程序”，再打开，再授权辅助功能权限。"
  printf '%s\n' "- 如果 macOS 提示 Apple 无法验证 JoyBridge，请点完成，再打开 系统设置 > 隐私与安全性 > 安全性，点击仍要打开。"
  printf '%s\n' "- Apple 通常只会在你尝试打开 App 后约一小时内显示仍要打开按钮。"
  printf '%s\n' "- 本地测试者备用命令，仅用于你信任的测试包：xattr -dr com.apple.quarantine /Applications/JoyBridge.app"
  printf '%s\n' "- Mac 重启后仍需要手动打开 JoyBridge，暂时没有开机自启。"
  printf '%s\n' "- 测试映射前，请给这个安装后的 JoyBridge 授权辅助功能权限。"
  printf '%s\n' "- 如果以前授权的是 Xcode 构建路径，请在辅助功能设置里移除/重新添加 JoyBridge。"
  printf '%s\n' "- 这个本地测试包的 Gatekeeper 检查可能显示 rejected 或代码签名内部错误。"
} > "$STAGING_DIR/READ-ME-FIRST.txt"

echo "==> Creating zip"
(
  cd "$STAGING_DIR"
  zip -qry -X "$ZIP_PATH" .
)

echo "==> Code signing info"
codesign -dvv "$STAGING_DIR/$APP_NAME" 2>&1 || true

echo "==> Gatekeeper assessment"
spctl -a -vv "$STAGING_DIR/$APP_NAME" 2>&1 || true

echo
echo "Done."
echo "ZIP: $ZIP_PATH"
