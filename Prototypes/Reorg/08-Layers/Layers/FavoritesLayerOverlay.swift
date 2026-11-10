import SwiftUI

struct FavoritesLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var body: some View {
        ZStack {
            ForEach(harness.favoriteCircles.filter { $0.hall == harness.hall }) { circle in
                LayerMarker(symbol: "star.fill", tint: harness.favorites[circle.id]?.color ?? .orange)
                    .position(layout.point(for: circle))
            }
        }
    }
}
