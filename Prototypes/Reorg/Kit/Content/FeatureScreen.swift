import SwiftUI

struct FeatureScreen: View {

    let feature: Feature

    var body: some View {
        Group {
            switch feature {
            case .map, .catalog: CatalogView()
            case .favorites: FavoritesView()
            case .buys: BuysView()
            case .sharedBuys: SharedBuysView()
            case .navigation: RouteView()
            case .myComiket: MyComiketView()
            case .eventData: EventDataView()
            case .settings: SettingsView()
            }
        }
        .navigationTitle(feature.title)
    }
}
