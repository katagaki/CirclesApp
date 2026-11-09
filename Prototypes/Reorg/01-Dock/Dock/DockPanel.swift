import SwiftUI

struct DockPanel: View {

    @Environment(Harness.self) var harness
    @State var tab: DockTab = .explore
    @State var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch tab {
                case .explore: CatalogView()
                case .saved: FavoritesView()
                case .buys: BuysView()
                case .me: DockMeView()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                VStack(spacing: 10.0) {
                    if tab == .explore || tab == .saved {
                        SearchField()
                    } else {
                        Text(tab.title)
                            .font(.title2.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 44.0)
                    }
                    GuestBanner()
                }
                .padding(.horizontal, 16.0)
                .padding(.top, 16.0)
                .padding(.bottom, 8.0)
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                DockBar(selection: $tab)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .featureDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let launchTab = DockTab(rawValue: screen) {
                tab = launchTab
            }
        }
    }
}
