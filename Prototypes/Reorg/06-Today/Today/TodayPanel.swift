import SwiftUI

struct TodayPanel: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var detent: PresentationDetent
    @State var path = NavigationPath()

    var isCompact: Bool {
        stageStyle == .sheet && detent == TodayRoot.compactDetent
    }

    var body: some View {
        NavigationStack(path: $path) {
            TodayFeed(isCompact: isCompact)
                .safeAreaInset(edge: .top, spacing: 0.0) {
                    TodayHeader(path: $path)
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                .featureDestinations()
                .navigationDestination(for: TodayDestination.self) { _ in
                    TodaySearchView()
                }
        }
        .onAppear {
            switch harness.launchScreen {
            case "search": path.append(TodayDestination.search)
            case "route": path.append(Feature.navigation)
            case let screen?: if let feature = Feature(rawValue: screen) { path.append(feature) }
            case nil: break
            }
        }
        .onChange(of: path.count) { _, count in
            if count > 0 && isCompact { detent = .large }
        }
    }
}
