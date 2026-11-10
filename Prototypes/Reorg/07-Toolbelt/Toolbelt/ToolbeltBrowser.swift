import SwiftUI

struct ToolbeltBrowser: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var detent: PresentationDetent
    @State var segment: ToolbeltSegment = .circles
    @State var path = NavigationPath()

    var isCompact: Bool {
        stageStyle == .sheet && detent == ToolbeltRoot.compactDetent
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch segment {
                case .circles: CatalogView()
                case .favorites: FavoritesView()
                case .buys: BuysView(showsSharedSection: false)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0.0) {
                ToolbeltBrowserHeader(segment: $segment, showsGuestBanner: !isCompact)
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .featureDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let launchSegment = ToolbeltSegment(rawValue: screen) {
                segment = launchSegment
            }
        }
        .onChange(of: harness.searchText) { old, new in
            if old.isEmpty && !new.isEmpty {
                segment = .circles
                if isCompact { detent = .medium }
            }
        }
        .onChange(of: path.count) { _, count in
            if count > 0 && isCompact { detent = .medium }
        }
    }
}
