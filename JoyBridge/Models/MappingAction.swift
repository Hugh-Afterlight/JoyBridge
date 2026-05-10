import Foundation

enum MappingAction: Codable, Equatable {
    case keyboard(key: KeyboardKey, modifiers: [KeyModifier])
    case modifierOnly(modifiers: [KeyModifier])
    case none

    init(key: KeyboardKey?, modifiers: [KeyModifier]) {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)

        if let key {
            self = .keyboard(key: key, modifiers: orderedModifiers)
        } else if !orderedModifiers.isEmpty {
            self = .modifierOnly(modifiers: orderedModifiers)
        } else {
            self = .none
        }
    }
}
