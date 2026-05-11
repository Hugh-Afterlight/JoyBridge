import Combine
import Foundation

@MainActor
final class MappingManager: ObservableObject {
    @Published private(set) var mappings: [KeyMapping] = []
    @Published private(set) var isMappingPaused: Bool

    private let userDefaultsKey = "joybridge.keyMappings"
    private let mappingPausedDefaultsKey = "joybridge.mappingPaused"
    private let userDefaults: UserDefaults
    private let keyboardEventSender: KeyboardEventSender
    private let accessibilityPermissionManager: AccessibilityPermissionManager
    private var activeModifierHolds: [ControllerButton: [KeyModifier]] = [:]

    init(
        accessibilityPermissionManager: AccessibilityPermissionManager,
        userDefaults: UserDefaults = .standard,
        keyboardEventSender: KeyboardEventSender? = nil
    ) {
        self.accessibilityPermissionManager = accessibilityPermissionManager
        self.userDefaults = userDefaults
        self.keyboardEventSender = keyboardEventSender ?? KeyboardEventSender()
        isMappingPaused = userDefaults.bool(forKey: mappingPausedDefaultsKey)

        print("Global mapping pause state loaded: \(isMappingPaused ? "paused" : "enabled")")
        loadMappings()
    }

    func mapping(for button: ControllerButton) -> KeyMapping? {
        mappings.first { $0.controllerButton == button }
    }

    func updateMapping(_ mapping: KeyMapping) {
        releaseModifierHold(for: mapping.controllerButton)

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
        guard !isMappingPaused else {
            print("Mapping skipped because global pause is enabled: \(button.displayName)")
            return
        }

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
        perform(mapping.action, for: button)
    }

    func handleButtonRelease(_ button: ControllerButton) {
        releaseModifierHold(for: button)
    }

    func setMappingPaused(_ isPaused: Bool) {
        guard isMappingPaused != isPaused else {
            return
        }

        isMappingPaused = isPaused
        userDefaults.set(isPaused, forKey: mappingPausedDefaultsKey)

        if isPaused {
            releaseAllHeldModifiers()
            print("Mappings paused; held modifiers released")
        } else {
            print("Mappings enabled")
        }
    }

    func toggleMappingPaused() {
        setMappingPaused(!isMappingPaused)
    }

    func releaseAllHeldModifiers() {
        let heldModifiers = KeyModifier.orderedUnique(from: activeModifierHolds.values.flatMap { $0 })
        guard !heldModifiers.isEmpty else { return }

        activeModifierHolds.removeAll()
        keyboardEventSender.sendModifierKeyUp(modifiers: heldModifiers)
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

    private func perform(_ action: MappingAction, for button: ControllerButton) {
        switch action {
        case let .keyboard(key, modifiers):
            let effectiveModifiers = modifiersIncludingActiveHolds(modifiers)
            keyboardEventSender.sendKeyCombo(key: key, modifiers: effectiveModifiers)
        case let .modifierOnly(modifiers):
            startModifierHold(modifiers, for: button)
        case .none:
            print("Mapping has no action: \(button.displayName)")
        }
    }

    private func startModifierHold(_ modifiers: [KeyModifier], for button: ControllerButton) {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)
        guard !orderedModifiers.isEmpty else { return }

        let alreadyHeldModifiers = Set(activeModifierHolds.values.flatMap { $0 })
        let modifiersToPress = orderedModifiers.filter { !alreadyHeldModifiers.contains($0) }

        activeModifierHolds[button] = orderedModifiers

        guard !modifiersToPress.isEmpty else {
            print("Modifier hold already active: \(KeyMapping.actionDisplayName(key: nil, modifiers: orderedModifiers))")
            return
        }

        keyboardEventSender.sendModifierKeyDown(modifiers: modifiersToPress)
    }

    private func releaseModifierHold(for button: ControllerButton) {
        guard let releasedModifiers = activeModifierHolds.removeValue(forKey: button) else {
            return
        }

        let stillHeldModifiers = Set(activeModifierHolds.values.flatMap { $0 })
        let modifiersToRelease = releasedModifiers.filter { !stillHeldModifiers.contains($0) }

        guard !modifiersToRelease.isEmpty else {
            print("Modifier hold released, modifiers still held by another button")
            return
        }

        keyboardEventSender.sendModifierKeyUp(modifiers: modifiersToRelease)
    }

    private func modifiersIncludingActiveHolds(_ modifiers: [KeyModifier]) -> [KeyModifier] {
        KeyModifier.orderedUnique(from: activeModifierHolds.values.flatMap { $0 } + modifiers)
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
