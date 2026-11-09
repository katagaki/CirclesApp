import SwiftUI

struct LayersPanelHeader: View {

    @Environment(LayersState.self) var layers
    @Binding var path: NavigationPath

    var body: some View {
        HStack(spacing: 10.0) {
            if let layer = layers.focused {
                LayerFocusHeader(layer: layer)
            } else {
                SearchField()
            }
            Button {
                path.append(LayersMeDestination())
            } label: {
                ProfileAvatar(size: 40.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Me")
        }
    }
}
