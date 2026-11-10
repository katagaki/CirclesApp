import SwiftUI

struct LayersMapOverlay: View {

    @Environment(LayersState.self) var layers
    let layout: HallMapLayout

    var body: some View {
        ZStack {
            ForEach(MapLayer.allCases.filter { layers.enabled.contains($0) }) { layer in
                let isDimmed = layers.focused != nil && layers.focused != layer
                content(for: layer)
                    .opacity(isDimmed ? 0.35 : 1.0)
                    .zIndex(layers.focused == layer ? 1.0 : 0.0)
            }
        }
        .animation(.snappy, value: layers.enabled)
        .animation(.snappy, value: layers.focused)
    }

    @ViewBuilder
    func content(for layer: MapLayer) -> some View {
        switch layer {
        case .favorites: FavoritesLayerOverlay(layout: layout)
        case .buys: BuysLayerOverlay(layout: layout)
        case .route: RouteLayerOverlay(layout: layout)
        case .friends: FriendsLayerOverlay(layout: layout)
        case .visited: VisitedLayerOverlay(layout: layout)
        case .genres: GenresLayerOverlay(layout: layout)
        }
    }
}
