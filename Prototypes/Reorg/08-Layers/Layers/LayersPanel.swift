import SwiftUI

struct LayersPanel: View {

    @Environment(LayersState.self) var layers
    @State var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            LayersPanelContent(layer: layers.focused)
                .id(layers.focused)
                .transition(.opacity)
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    VStack(spacing: 10.0) {
                        LayersPanelHeader(path: $path)
                        GuestBanner()
                    }
                    .padding(.horizontal, 16.0)
                    .padding(.top, 16.0)
                    .padding(.bottom, 8.0)
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                .featureDestinations()
                .navigationDestination(for: LayersMeDestination.self) { _ in
                    LayersMeView()
                }
        }
    }
}
