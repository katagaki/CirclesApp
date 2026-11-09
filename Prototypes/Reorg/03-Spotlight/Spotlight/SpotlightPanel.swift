import SwiftUI

struct SpotlightPanel: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var detent: PresentationDetent
    @State var path = NavigationPath()
    @State var settings = SpotlightSettings()

    var body: some View {
        NavigationStack(path: $path) {
            SpotlightHome(path: $path)
                .toolbarVisibility(.hidden, for: .navigationBar)
                .featureDestinations()
        }
        .environment(settings)
        .onAppear {
            if let screen = harness.launchScreen, let feature = Feature(rawValue: screen) {
                path.append(feature)
            }
        }
        .onChange(of: harness.searchText) { _, text in
            if !text.isEmpty && stageStyle == .sheet && detent == SpotlightRoot.compactDetent {
                detent = .medium
            }
        }
    }
}
