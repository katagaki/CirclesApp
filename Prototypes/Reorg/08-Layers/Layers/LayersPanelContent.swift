import SwiftUI

struct LayersPanelContent: View {

    let layer: MapLayer?

    var body: some View {
        switch layer {
        case nil: CatalogView()
        case .favorites: FavoritesView()
        case .buys: BuysView()
        case .route: RouteView()
        case .friends: SharedBuysView()
        case .visited: LayersVisitedList()
        case .genres: LayersGenreList()
        }
    }
}
