import SwiftUI

struct PlanPanel: View {

    static let pushedScreens: [String: Feature] = [
        "myComiket": .myComiket, "eventData": .eventData, "settings": .settings, "catalog": .catalog
    ]

    @Environment(Harness.self) var harness
    @State var segment: PlanSegment = .circles
    @State var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch segment {
                case .circles: CatalogView()
                case .favorites: FavoritesView()
                case .buys: BuysView()
                case .prep: PlanPrepView()
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                PlanHeader(segment: $segment)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .featureDestinations()
        }
        .onAppear {
            guard let screen = harness.launchScreen else { return }
            if let launchSegment = PlanSegment(rawValue: screen) {
                segment = launchSegment
            } else if let feature = PlanPanel.pushedScreens[screen] {
                if feature == .myComiket || feature == .eventData {
                    segment = .prep
                }
                path.append(feature)
            }
        }
    }
}
