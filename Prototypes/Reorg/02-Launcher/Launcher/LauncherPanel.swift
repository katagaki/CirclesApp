import SwiftUI

struct LauncherPanel: View {

    @Environment(Harness.self) var harness
    @Environment(\.stageStyle) var stageStyle
    @Binding var detent: PresentationDetent
    @State var path = NavigationPath()

    var isCompact: Bool {
        stageStyle == .sheet && detent == LauncherRoot.compactDetent
    }

    var body: some View {
        NavigationStack(path: $path) {
            LauncherHome(isCompact: isCompact)
                .toolbarVisibility(.hidden, for: .navigationBar)
                .featureDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let feature = Feature(rawValue: screen) {
                path.append(feature)
            }
        }
        .onChange(of: path.count) { _, count in
            if count > 0 && isCompact {
                detent = .medium
            }
        }
        .onChange(of: harness.searchText) { _, text in
            if !text.isEmpty && isCompact {
                detent = .medium
            }
        }
    }
}
