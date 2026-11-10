import SwiftUI

struct LayerFocusHeader: View {

    @Environment(LayersState.self) var layers
    let layer: MapLayer

    var body: some View {
        HStack(spacing: 10.0) {
            Image(systemName: layer.symbol)
                .font(.system(size: 16.0, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36.0, height: 36.0)
                .background(layer.tint.gradient, in: .circle)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(layer.title).font(.title3.weight(.bold))
                Text("Map layer").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
            Button {
                withAnimation(.snappy) { layers.hide(layer) }
            } label: {
                Image(systemName: "eye.slash")
                    .frame(width: 22.0, height: 22.0)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Hide Layer")
            Button {
                withAnimation(.snappy) { layers.focused = nil }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .frame(width: 22.0, height: 22.0)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Show Catalog")
        }
        .frame(height: 44.0)
    }
}
