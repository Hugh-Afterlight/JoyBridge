import CoreGraphics
import Foundation

final class KeyboardEventSender {
    func sendKeyCombo(key: KeyboardKey, modifiers: [KeyModifier]) {
        let orderedModifiers = KeyModifier.orderedUnique(from: modifiers)
        let flags = KeyModifier.eventFlags(for: orderedModifiers)
        let source = CGEventSource(stateID: .hidSystemState)

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key.keyCode, keyDown: false)
        else {
            print("Keyboard event failed: \(KeyMapping.actionDisplayName(key: key, modifiers: orderedModifiers))")
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        print("Keyboard event sent: \(KeyMapping.actionDisplayName(key: key, modifiers: orderedModifiers))")
    }
}
