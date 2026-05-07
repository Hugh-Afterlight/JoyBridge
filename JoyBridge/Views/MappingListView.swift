import SwiftUI

struct MappingListView: View {
    @EnvironmentObject private var mappingManager: MappingManager

    var body: some View {
        GroupBox("映射配置") {
            VStack(spacing: 0) {
                ForEach(mappingManager.mappings) { mapping in
                    MappingRowView(mapping: mapping) { updatedMapping in
                        mappingManager.updateMapping(updatedMapping)
                    }

                    if mapping.id != mappingManager.mappings.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}
