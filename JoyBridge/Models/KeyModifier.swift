import CoreGraphics
import Foundation

enum KeyModifier: String, CaseIterable, Codable, Identifiable {
    case command
    case option
    case control
    case shift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .command:
            "Command"
        case .option:
            "Option"
        case .control:
            "Control"
        case .shift:
            "Shift"
        }
    }

    var eventFlag: CGEventFlags {
        switch self {
        case .command:
            .maskCommand
        case .option:
            .maskAlternate
        case .control:
            .maskControl
        case .shift:
            .maskShift
        }
    }

    var keyCode: CGKeyCode {
        // Left-side macOS virtual key codes used for real modifier key events.
        switch self {
        case .command:
            55
        case .option:
            58
        case .control:
            59
        case .shift:
            56
        }
    }

    static func eventFlags(for modifiers: [KeyModifier]) -> CGEventFlags {
        orderedUnique(from: modifiers).reduce(CGEventFlags(rawValue: 0)) { flags, modifier in
            flags.union(modifier.eventFlag)
        }
    }

    static func orderedUnique(from modifiers: [KeyModifier]) -> [KeyModifier] {
        allCases.filter { modifiers.contains($0) }
    }
}
