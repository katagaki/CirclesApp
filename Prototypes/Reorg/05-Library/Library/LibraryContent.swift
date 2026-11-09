import SwiftUI

struct LibraryContent: View {

    let item: LibraryItem

    var body: some View {
        Group {
            switch item {
            case .allCircles: CatalogView()
            case .genres: LibraryGenresView()
            case .search: LibrarySearchView()
            case .favorites: FavoritesView()
            case .favoriteColor(let color): LibraryFavoriteColorView(color: color)
            case .buys: BuysView(showsSharedSection: false)
            case .sharedBuys: SharedBuysView()
            case .route: RouteView()
            case .visited: LibraryVisitedView()
            case .myComiket: MyComiketView()
            case .eventData: EventDataView()
            case .settings: SettingsView()
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
