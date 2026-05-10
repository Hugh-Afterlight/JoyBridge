import SwiftUI

struct MappingRowView: View {
    let mapping: KeyMapping
    let onUpdate: (KeyMapping) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(mapping.controllerButton.displayName)
                    .font(.headline)
                    .frame(width: 96, alignment: .leading)

                Toggle("启用", isOn: enabledBinding)
                    .toggleStyle(.checkbox)
                    .frame(width: 76, alignment: .leading)

                ForEach(KeyModifier.allCases) { modifier in
                    Toggle(modifier.displayName, isOn: modifierBinding(for: modifier))
                        .toggleStyle(.checkbox)
                        .frame(width: 102, alignment: .leading)
                }

                Picker("Key", selection: keyBinding) {
                    Text("None/无").tag(nil as KeyboardKey?)

                    ForEach(KeyboardKey.allCases) { key in
                        Text(key.displayName).tag(key as KeyboardKey?)
                    }
                }
                .frame(width: 190)

                Spacer()
            }

            Text("预览：\(previewDescription)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            mapping.isEnabled
        } set: { isEnabled in
            var updatedMapping = mapping
            updatedMapping.isEnabled = isEnabled
            onUpdate(updatedMapping)
        }
    }

    private var keyBinding: Binding<KeyboardKey?> {
        Binding {
            mapping.key
        } set: { key in
            var updatedMapping = mapping
            updatedMapping.key = key
            onUpdate(updatedMapping)
        }
    }

    private var previewDescription: String {
        "\(mapping.controllerButton.displayName) -> \(actionDisplayName)"
    }

    private var actionDisplayName: String {
        let modifierNames = KeyModifier.orderedUnique(from: mapping.modifiers).map(\.displayName)

        if let key = mapping.key {
            return (modifierNames + [key.displayName]).joined(separator: " + ")
        }

        if modifierNames.isEmpty {
            return "None/无"
        }

        return modifierNames.joined(separator: " + ")
    }

    private func modifierBinding(for modifier: KeyModifier) -> Binding<Bool> {
        Binding {
            mapping.modifiers.contains(modifier)
        } set: { isEnabled in
            onUpdate(mapping.settingModifier(modifier, enabled: isEnabled))
        }
    }
}
