import Foundation

enum AppInfo {
    static let currentTestVersion = "v0.10.0"
    static let releaseDate = "2026-05-11"

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown Bundle ID"
    }
}
