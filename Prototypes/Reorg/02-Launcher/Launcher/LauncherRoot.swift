import SwiftUI

struct LauncherRoot: View {

    static let compactDetent: PresentationDetent = .height(176)

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    var body: some View {
        MapStage(detent: $detent, detents: [LauncherRoot.compactDetent, .medium, .large], sheetMapInset: 176.0) {
            LauncherPanel(detent: $detent)
        } chrome: {
            LauncherMapChrome()
        }
        .onAppear {
            let launchDetent = harness.detent(default: .medium)
            detent = launchDetent == .height(120) ? LauncherRoot.compactDetent : launchDetent
        }
    }
}
