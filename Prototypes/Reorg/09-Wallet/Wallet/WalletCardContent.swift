import SwiftUI

struct WalletCardContent: View {

    let card: WalletCard

    var body: some View {
        switch card {
        case .catalog:
            CatalogView()
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    SearchField()
                        .padding(.horizontal, 12.0)
                        .padding(.top, 12.0)
                        .padding(.bottom, 4.0)
                }
        case .favorites: FavoritesView()
        case .buys: BuysView(showsSharedSection: false)
        case .sharedBuys: SharedBuysView()
        case .navigation: RouteView()
        case .myComiket: MyComiketView()
        case .settings: SettingsView()
        }
    }
}
