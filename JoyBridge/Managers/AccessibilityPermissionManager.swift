import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    @Published private(set) var isTrusted = false
    @Published private(set) var lastCheckedDescription = "尚未检测"
    @Published private(set) var currentAppPath = Bundle.main.bundlePath

    private var lastAutomaticRefreshDate = Date.distantPast

    init() {
        refreshPermissionStatus(reason: "startup")
    }

    func refreshPermissionStatus(reason: String = "manual") {
        updatePermissionStatus(shouldPrompt: false, reason: reason)
    }

    func refreshPermissionStatusIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastAutomaticRefreshDate) > 1.0 else {
            return
        }

        lastAutomaticRefreshDate = now
        refreshPermissionStatus(reason: "app became active")
    }

    func requestPermissionAndOpenSettings() {
        updatePermissionStatus(shouldPrompt: true, reason: "user requested permission")

        if !isTrusted {
            openAccessibilitySettings()
        }
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func updatePermissionStatus(shouldPrompt: Bool, reason: String) {
        currentAppPath = Bundle.main.bundlePath

        let directTrustStatus = AXIsProcessTrusted()
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: shouldPrompt] as CFDictionary
        let optionsTrustStatus = AXIsProcessTrustedWithOptions(options)

        isTrusted = directTrustStatus || optionsTrustStatus
        lastCheckedDescription = Self.formattedCheckTime()

        if isTrusted {
            print("Accessibility permission granted")
        } else {
            print("Accessibility permission missing")
        }

        print(
            "Accessibility permission check reason=\(reason), " +
            "Accessibility permission check: AXIsProcessTrusted=\(directTrustStatus), " +
            "AXIsProcessTrustedWithOptions=\(optionsTrustStatus), " +
            "prompt=\(shouldPrompt), " +
            "bundleID=\(Bundle.main.bundleIdentifier ?? "unknown"), " +
            "bundlePath=\(Bundle.main.bundlePath)"
        )
    }

    private static func formattedCheckTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return "上次检测：\(formatter.string(from: Date()))"
    }
}
