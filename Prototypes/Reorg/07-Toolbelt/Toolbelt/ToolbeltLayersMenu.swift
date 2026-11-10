import SwiftUI

struct ToolbeltLayersMenu: View {

    @Binding var layers: ToolbeltLayers

    var body: some View {
        Menu {
            Section("Show on Map") {
                Toggle("Favorites", systemImage: "star", isOn: $layers.showsFavorites)
                Toggle("Visited", systemImage: "checkmark.circle", isOn: $layers.showsVisited)
                Toggle("Genre Colors", systemImage: "theatermasks", isOn: $layers.showsGenres)
            }
        } label: {
            Image(systemName: layers.isDefault ? "square.3.layers.3d" : "square.3.layers.3d.top.filled")
                .font(.system(size: 18.0, weight: .medium))
                .foregroundStyle(layers.isDefault ? Color.primary : Color.accentColor)
                .frame(width: 48.0, height: 48.0)
                .contentShape(.rect)
        }
        .menuActionDismissBehavior(.disabled)
        .accessibilityLabel("Layers")
    }
}
