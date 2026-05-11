#!/usr/bin/env bash

set -uo pipefail

STRICT=false
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=true
  shift
fi

EXPECTED_VERSION="${1:-}"
APP_PATH="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$REPO_ROOT/JoyBridge.xcodeproj/project.pbxproj"
APP_INFO_FILE="$REPO_ROOT/JoyBridge/Utilities/AppInfo.swift"
APP_ICON_DIR="$REPO_ROOT/JoyBridge/Assets.xcassets/AppIcon.appiconset"

WARNINGS=0

ok() {
  printf 'OK: %s\n' "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf 'WARN: %s\n' "$1"
}

info() {
  printf 'INFO: %s\n' "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_header() {
  printf '\n==> %s\n' "$1"
}

print_header "JoyBridge release readiness"
if [[ -n "$EXPECTED_VERSION" ]]; then
  info "Expected version: $EXPECTED_VERSION"
fi
if [[ -n "$APP_PATH" ]]; then
  info "App path: $APP_PATH"
fi
info "Repo: $REPO_ROOT"

print_header "Git"
if command_exists git && git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
  GIT_BRANCH="$(git -C "$REPO_ROOT" branch --show-current)"
  GIT_TAG="$(git -C "$REPO_ROOT" describe --tags --exact-match HEAD 2>/dev/null || true)"
  GIT_STATUS="$(git -C "$REPO_ROOT" status --porcelain --untracked-files=normal)"

  info "Commit: $GIT_COMMIT"
  info "Branch: ${GIT_BRANCH:-detached}"
  info "Tag at HEAD: ${GIT_TAG:-none}"

  if [[ -z "$GIT_STATUS" ]]; then
    ok "Worktree is clean"
  else
    warn "Worktree is dirty; commit or stash changes before making a public release"
  fi

  if [[ -n "$EXPECTED_VERSION" ]]; then
    if [[ "$GIT_TAG" == "$EXPECTED_VERSION" ]]; then
      ok "Git tag matches expected version"
    else
      warn "Git tag does not match expected version"
    fi
  fi
else
  warn "Git repository information is unavailable"
fi

print_header "Versions"
APP_INFO_VERSION="$(awk -F '"' '/currentTestVersion/ { print $2; exit }' "$APP_INFO_FILE" 2>/dev/null || true)"
MARKETING_VERSIONS="$(awk -F '= ' '/MARKETING_VERSION/ { gsub(";", "", $2); print $2 }' "$PROJECT_FILE" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')"

if [[ -n "$APP_INFO_VERSION" ]]; then
  ok "AppInfo version: $APP_INFO_VERSION"
else
  warn "Could not read AppInfo.currentTestVersion"
fi

if [[ -n "$MARKETING_VERSIONS" ]]; then
  info "MARKETING_VERSION values: $MARKETING_VERSIONS"
  if [[ "$(printf '%s\n' "$MARKETING_VERSIONS" | wc -w | tr -d ' ')" == "1" ]]; then
    ok "Project marketing version is consistent"
  else
    warn "Project has multiple MARKETING_VERSION values"
  fi
else
  warn "Could not read MARKETING_VERSION from project"
fi

if [[ -n "$EXPECTED_VERSION" ]]; then
  EXPECTED_MARKETING_VERSION="${EXPECTED_VERSION#v}"
  if [[ "$APP_INFO_VERSION" == "$EXPECTED_VERSION" ]]; then
    ok "AppInfo version matches expected version"
  else
    warn "AppInfo version does not match expected version"
  fi

  if [[ "$MARKETING_VERSIONS" == "$EXPECTED_MARKETING_VERSION" ]]; then
    ok "Bundle marketing version matches expected version"
  else
    warn "Bundle marketing version does not match expected version"
  fi
fi

print_header "Xcode tools"
if command_exists xcodebuild; then
  XCODEBUILD_VERSION="$(xcodebuild -version 2>&1 || true)"
  if [[ "$XCODEBUILD_VERSION" == Xcode* ]]; then
    ok "xcodebuild is available"
    printf '%s\n' "$XCODEBUILD_VERSION" | sed 's/^/INFO: /'
  else
    warn "xcodebuild is present but not usable with the active developer directory"
    printf '%s\n' "$XCODEBUILD_VERSION" | sed 's/^/INFO: xcodebuild: /'
  fi
else
  warn "xcodebuild is not available"
fi

if command_exists xcrun && xcrun --find notarytool >/dev/null 2>&1; then
  ok "notarytool is available"
else
  warn "notarytool is not available"
fi

if command_exists xcrun && xcrun --find stapler >/dev/null 2>&1; then
  ok "stapler is available"
else
  warn "stapler is not available"
fi

print_header "Signing and notarization prerequisites"
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
  ok "Developer ID Application certificate is available"
else
  warn "Developer ID Application certificate was not found in the keychain"
fi

if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Installer"; then
  ok "Developer ID Installer certificate is available"
else
  info "Developer ID Installer certificate not found; it is only needed for signed pkg installers"
fi

if [[ -f "$PROJECT_FILE" ]] && grep -q "ENABLE_HARDENED_RUNTIME = YES" "$PROJECT_FILE"; then
  ok "Hardened Runtime is enabled in project settings"
elif [[ -f "$PROJECT_FILE" ]]; then
  warn "Hardened Runtime is not enabled; Developer ID notarization expects it"
else
  warn "Project settings file was not found; run from the source repository for full project checks"
fi

if [[ -f "$PROJECT_FILE" ]] && grep -q "ENABLE_APP_SANDBOX = NO" "$PROJECT_FILE"; then
  info "App Sandbox is disabled; this is expected for the current local testing setup"
fi

if [[ -n "${JOYBRIDGE_NOTARY_PROFILE:-}" ]]; then
  info "Notary keychain profile requested: $JOYBRIDGE_NOTARY_PROFILE"
  info "This script does not contact Apple. Validate manually with: xcrun notarytool history --keychain-profile \"$JOYBRIDGE_NOTARY_PROFILE\""
else
  warn "JOYBRIDGE_NOTARY_PROFILE is not set; notarization credentials are not configured for this shell"
fi

print_header "App icon"
ICON_FILENAMES="$(grep -c '"filename"' "$APP_ICON_DIR/Contents.json" 2>/dev/null || printf '0')"
ICON_PNGS="$(find "$APP_ICON_DIR" -maxdepth 1 -name '*.png' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$ICON_FILENAMES" == "10" && "$ICON_PNGS" == "10" ]]; then
  ok "macOS AppIcon assets are present"
else
  warn "Expected 10 macOS AppIcon PNG files and 10 filename entries; found $ICON_PNGS PNG files and $ICON_FILENAMES filename entries"
fi

if [[ -n "$APP_PATH" ]]; then
  print_header "Built app checks"

  if [[ -d "$APP_PATH" ]]; then
    ok "App bundle exists"
  else
    warn "App bundle does not exist at: $APP_PATH"
  fi

  if [[ -f "$APP_PATH/Contents/Info.plist" ]]; then
    BUILT_VERSION="$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
    if [[ -n "$BUILT_VERSION" ]]; then
      ok "Built app version: $BUILT_VERSION"
      if [[ -n "$EXPECTED_VERSION" && "$BUILT_VERSION" != "${EXPECTED_VERSION#v}" ]]; then
        warn "Built app version does not match expected version"
      fi
    else
      warn "Could not read built app version"
    fi
  else
    warn "Built app Info.plist not found"
  fi

  if [[ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]]; then
    ok "Built app contains AppIcon.icns"
  else
    warn "Built app does not contain AppIcon.icns"
  fi

  if [[ -f "$APP_PATH/Contents/Resources/Assets.car" ]]; then
    ok "Built app contains Assets.car"
  else
    warn "Built app does not contain Assets.car"
  fi

  if [[ -x "$APP_PATH/Contents/MacOS/JoyBridge" ]]; then
    LIPO_OUTPUT="$(lipo -info "$APP_PATH/Contents/MacOS/JoyBridge" 2>/dev/null || true)"
    if [[ "$LIPO_OUTPUT" == *"arm64"* && "$LIPO_OUTPUT" == *"x86_64"* ]]; then
      ok "Built app is Universal: $LIPO_OUTPUT"
    elif [[ "$LIPO_OUTPUT" == *"arm64"* ]]; then
      info "Built app is Apple Silicon only: $LIPO_OUTPUT"
    else
      warn "Could not confirm built app architecture"
    fi
  else
    warn "Built app executable not found"
  fi

  CODESIGN_OUTPUT="$(codesign -dvv "$APP_PATH" 2>&1 || true)"
  if [[ "$CODESIGN_OUTPUT" == *"Authority=Developer ID Application"* ]]; then
    ok "Built app is signed with Developer ID Application"
  elif [[ "$CODESIGN_OUTPUT" == *"Signature=adhoc"* || "$CODESIGN_OUTPUT" == *"Authority="* ]]; then
    warn "Built app is signed, but not with Developer ID Application"
  else
    warn "Could not read built app signing authority"
  fi

  if [[ "$CODESIGN_OUTPUT" == *"flags="*"runtime"* ]]; then
    ok "Built app signature has Hardened Runtime flag"
  else
    warn "Built app signature does not show Hardened Runtime flag"
  fi

  if [[ "$CODESIGN_OUTPUT" == *"Timestamp="* || "$CODESIGN_OUTPUT" == *"Signed Time="* ]]; then
    info "Built app includes signing time information"
  else
    info "Built app has no secure timestamp information; this is expected for local ad-hoc test signing"
  fi

  ENTITLEMENTS_OUTPUT="$(codesign -d --entitlements :- "$APP_PATH" 2>/dev/null || true)"
  if [[ "$ENTITLEMENTS_OUTPUT" == *"com.apple.security.get-task-allow"* && "$ENTITLEMENTS_OUTPUT" == *"<true/>"* ]]; then
    warn "Built app has get-task-allow=true; this must be false or absent for public Developer ID distribution"
  elif [[ -n "$ENTITLEMENTS_OUTPUT" ]]; then
    ok "Built app does not expose get-task-allow=true"
  else
    info "No entitlements output was available"
  fi

  if codesign --verify --deep --strict "$APP_PATH" >/dev/null 2>&1; then
    ok "codesign verification passed"
  else
    warn "codesign verification failed"
  fi

  SPCTL_OUTPUT="$(spctl -a -vv "$APP_PATH" 2>&1 || true)"
  if [[ "$SPCTL_OUTPUT" == *"accepted"* ]]; then
    ok "Gatekeeper assessment accepted the app"
  else
    warn "Gatekeeper assessment did not accept the app"
    printf '%s\n' "$SPCTL_OUTPUT" | sed 's/^/INFO: spctl: /'
  fi

  if command_exists xcrun && xcrun stapler validate "$APP_PATH" >/dev/null 2>&1; then
    ok "Stapled notarization ticket is present"
  else
    warn "No stapled notarization ticket was found"
  fi
fi

print_header "Summary"
if [[ "$WARNINGS" -eq 0 ]]; then
  ok "No readiness warnings found"
else
  warn "$WARNINGS readiness warning(s) found"
  info "For local friend testing, some warnings may be expected. For public distribution, resolve them before release."
fi

if [[ "$STRICT" == "true" && "$WARNINGS" -gt 0 ]]; then
  exit 1
fi

exit 0
