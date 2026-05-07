import Foundation

enum MappingAction: Codable, Equatable {
    case keyboard(key: KeyboardKey, modifiers: [KeyModifier])
    case none
}
