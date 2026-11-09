import SwiftUI

struct LayerChipBar: View {

    @Environment(LayersState.self) var layers

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: 8.0) {
                    HStack(spacing: 8.0) {
                        ForEach(MapLayer.allCases) { layer in
                            LayerChip(layer: layer)
                                .id(layer)
                        }
                    }
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 4.0)
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: layers.focused, initial: true) { _, focused in
                if let focused {
                    withAnimation(.snappy) { reader.scrollTo(focused, anchor: .center) }
                }
            }
        }
    }
}
