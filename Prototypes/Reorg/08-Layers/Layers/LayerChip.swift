import SwiftUI

struct LayerChip: View {

    @Environment(LayersState.self) var layers
    let layer: MapLayer

    var isOn: Bool { layers.enabled.contains(layer) }
    var isFocused: Bool { layers.focused == layer }

    var body: some View {
        Button {
            withAnimation(.snappy) { layers.tap(layer) }
        } label: {
            HStack(spacing: 6.0) {
                Image(systemName: layer.symbol)
                    .font(.system(size: 13.0, weight: .semibold))
                    .foregroundStyle(isFocused ? Color.white : (isOn ? layer.tint : Color.secondary))
                Text(layer.title)
                    .font(.subheadline.weight(isOn ? .semibold : .medium))
                    .foregroundStyle(isFocused ? Color.white : Color.primary)
            }
            .padding(.horizontal, 12.0)
            .frame(height: 34.0)
            .overlay(alignment: .bottom) {
                if isOn && !isFocused {
                    Capsule().fill(layer.tint).frame(width: 14.0, height: 3.0).offset(y: -2.0)
                }
            }
        }
        .buttonStyle(.plain)
        .glassEffect(isFocused ? .regular.tint(layer.tint).interactive() : .regular.interactive(), in: .capsule)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
