import Combine
import Foundation

@MainActor
final class MappingManager: ObservableObject {
    @Published private(set) var mappings: [KeyMapping] = []

    private let userDefaultsKey = "joybridge.keyMappings"
    private let userDefaults: UserDefaults
    private let keyboardEventSender: KeyboardEventSender
    private let accessibilityPermissionManager: AccessibilityPermissionManager

    init(
        accessibilityPermissionManager: AccessibilityPermissionManager,
        userDefaults: UserDefaults = .standard,
        keyboardEventSender: KeyboardEventSender? = nil
    ) {
        self.accessibilityPermissionManager = accessibilityPermissionManager
        self.userDefaults = userDefaults
        self.keyboardEventSender = keyboardEventSender ?? KeyboardEventSender()

        loadMappings()
    }

    func mapping(for button: ControllerButton) -> KeyMapping? {
        mappings.first { $0.controllerButton == button }
    }

    func updateMapping(_ mapping: KeyMapping) {
        let normalizedMapping = mapping.normalized()
        var updatedMappings = mappings

        if let index = updatedMappings.firstIndex(where: { $0.controllerButton == normalizedMapping.controllerButton }) {
            updatedMappings[index] = normalizedMapping
        } else {
            updatedMappings.append(normalizedMapping)
        }

        mappings = normalizedMappings(updatedMappings)
        saveMappings()
    }

    func handleButtonPress(_ button: ControllerButton) {
        guard let mapping = mapping(for: button) else {
            print("Mapping missing: \(button.displayName)")
            return
        }

        guard mapping.isEnabled else {
            print("Mapping disabled: \(button.displayName)")
            return
        }

        guard accessibilityPermissionManager.isTrusted else {
            print("Accessibility permission missing")
            return
        }

        print("Mapping found: \(mapping.previewDescription)")
        keyboardEventSender.sendKeyCombo(key: mapping.key, modifiers: mapping.modifiers)
    }

    private func loadMappings() {
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            mappings = Self.defaultMappings()
            print("Default mappings created")
            saveMappings()
            return
        }

        do {
            let decodedMappings = try JSONDecoder().decode([KeyMapping].self, from: data)
            mappings = normalizedMappings(decodedMappings)
            print("Mappings loaded from UserDefaults")
        } catch {
            mappings = Self.defaultMappings()
            print("Default mappings created")
            saveMappings()
        }
    }

    private func saveMappings() {
        do {
            let data = try JSONEncoder().encode(mappings)
            userDefaults.set(data, forKey: userDefaultsKey)
            print("Mappings saved")
        } catch {
            print("Mappings save failed: \(error.localizedDescription)")
        }
    }

    private func normalizedMappings(_ sourceMappings: [KeyMapping]) -> [KeyMapping] {
        let defaults = Self.defaultMappings()

        return ControllerButton.mappableButtons.compactMap { button in
            if let mapping = sourceMappings.first(where: { $0.controllerButton == button }) {
                return mapping.normalized()
            }

            return defaults.first { $0.controllerButton == button }
        }
    }

    static func defaultMappings() -> [KeyMapping] {
        [
            KeyMapping(controllerButton: .a, key: .space),
            KeyMapping(controllerButton: .b, key: .escape),
            KeyMapping(controllerButton: .x, key: .c, modifiers: [.command]),
            KeyMapping(controllerButton: .y, key: .v, modifiers: [.command]),
            KeyMapping(controllerButton: .leftShoulder, key: .leftArrow, modifiers: [.command]),
            KeyMapping(controllerButton: .rightShoulder, key: .rightArrow, modifiers: [.command]),
            KeyMapping(controllerButton: .leftTrigger, key: .pageUp),
            KeyMapping(controllerButton: .rightTrigger, key: .pageDown),
            KeyMapping(controllerButton: .dpadUp, key: .upArrow),
            KeyMapping(controllerButton: .dpadDown, key: .downArrow),
            KeyMapping(controllerButton: .dpadLeft, key: .leftArrow),
            KeyMapping(controllerButton: .dpadRight, key: .rightArrow)
        ]
    }
}
