import Foundation

struct KeyMapping: Codable, Identifiable, Equatable {
    var id: String
    var controllerButton: ControllerButton
    var key: KeyboardKey?
    var modifiers: [KeyModifier]
    var isEnabled: Bool

    init(
        id: String? = nil,
        controllerButton: ControllerButton,
        key: KeyboardKey?,
        modifiers: [KeyModifier] = [],
        isEnabled: Bool = true
    ) {
        self.id = id ?? controllerButton.rawValue
        self.controllerButton = controllerButton
        self.key = key
        self.modifiers = KeyModifier.orderedUnique(from: modifiers)
        self.isEnabled = isEnabled
    }

    var actionDisplayName: String {
        Self.actionDisplayName(key: key, modifiers: modifiers)
    }

    var action: MappingAction {
        MappingAction(key: key, modifiers: modifiers)
    }

    var previewDescription: String {
        "\(controllerButton.displayName) -> \(actionDisplayName)"
    }

    func normalized() -> KeyMapping {
        KeyMapping(
            id: controllerButton.rawValue,
            controllerButton: controllerButton,
            key: key,
            modifiers: modifiers,
            isEnabled: isEnabled
        )
    }

    func settingModifier(_ modifier: KeyModifier, enabled: Bool) -> KeyMapping {
        var updatedModifiers = modifiers

        if enabled {
            updatedModifiers.append(modifier)
        } else {
            updatedModifiers.removeAll { $0 == modifier }
        }

        return KeyMapping(
            controllerButton: controllerButton,
            key: key,
            modifiers: updatedModifiers,
            isEnabled: isEnabled
        )
    }

    static func actionDisplayName(key: KeyboardKey?, modifiers: [KeyModifier]) -> String {
        let modifierNames = KeyModifier.orderedUnique(from: modifiers).map(\.displayName)

        if let key {
            return (modifierNames + [key.displayName]).joined(separator: " + ")
        }

        if !modifierNames.isEmpty {
            return modifierNames.joined(separator: " + ")
        }

        return "None"
    }
}
