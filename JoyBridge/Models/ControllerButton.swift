import Foundation

enum ControllerButton: String, CaseIterable, Codable, Identifiable {
    case a
    case b
    case x
    case y
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case dpadUp
    case dpadDown
    case dpadLeft
    case dpadRight
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .a:
            "A"
        case .b:
            "B"
        case .x:
            "X"
        case .y:
            "Y"
        case .leftShoulder:
            "L"
        case .rightShoulder:
            "R"
        case .leftTrigger:
            "ZL"
        case .rightTrigger:
            "ZR"
        case .dpadUp:
            "DPad Up"
        case .dpadDown:
            "DPad Down"
        case .dpadLeft:
            "DPad Left"
        case .dpadRight:
            "DPad Right"
        case .unknown:
            "Unknown"
        }
    }

    static var mappableButtons: [ControllerButton] {
        allCases.filter { $0 != .unknown }
    }
}
