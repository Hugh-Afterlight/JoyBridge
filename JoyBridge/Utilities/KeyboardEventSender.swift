import CoreGraphics
import Foundation

final class KeyboardEventSender {
    @discardableResult
    func sendKeyCombo(key: KeyboardKey, modifiers: [KeyModifier]) -> Bool {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)
        let flags = KeyModifier.eventFlags(for: orderedModifiers)
        let source = CGEventSource(stateID: .hidSystemState)

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: false)
        else {
            print("Keyboard event failed: \(KeyMapping.actionDisplayName(key: key, modifiers: orderedModifiers))")
            return false
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        print("Keyboard event sent: \(KeyMapping.actionDisplayName(key: key, modifiers: orderedModifiers))")
        return true
    }

    @discardableResult
    func sendModifierKeyDown(modifiers: [KeyModifier]) -> Bool {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)
        guard !orderedModifiers.isEmpty else { return false }

        let didSend = postModifierEvents(orderedModifiers, keyDown: true)
        if didSend {
            print("Modifier keyDown sent: \(KeyMapping.actionDisplayName(key: nil, modifiers: orderedModifiers))")
        }

        return didSend
    }

    @discardableResult
    func sendModifierKeyUp(modifiers: [KeyModifier]) -> Bool {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)
        guard !orderedModifiers.isEmpty else { return false }

        let didSend = postModifierEvents(orderedModifiers, keyDown: false)
        if didSend {
            print("Modifier keyUp sent: \(KeyMapping.actionDisplayName(key: nil, modifiers: orderedModifiers))")
        }

        return didSend
    }

    private func postModifierEvents(_ modifiers: [KeyModifier], keyDown: Bool) -> Bool {
        let source = CGEventSource(stateID: .hidSystemState)
        let eventModifiers = keyDown ? modifiers : Array(modifiers.reversed())
        var activeModifiers = keyDown ? [] : modifiers

        for modifier in eventModifiers {
            if keyDown {
                activeModifiers.append(modifier)
            } else {
                activeModifiers.removeAll { $0 == modifier }
            }

            guard let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: modifier.keyCode,
                keyDown: keyDown
            ) else {
                print("Modifier event failed: \(modifier.displayName)")
                return false
            }

            event.flags = KeyModifier.eventFlags(for: activeModifiers)
            event.post(tap: .cghidEventTap)
        }

        return true
    }
}
