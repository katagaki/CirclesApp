import SwiftUI

struct SpotlightRoot: View {

    static let compactDetent: PresentationDetent = .height(150)

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    var body: some View {
        MapStage(detent: $detent, detents: [SpotlightRoot.compactDetent, .medium, .large], sheetMapInset: 150.0) {
            SpotlightPanel(detent: $detent)
        } chrome: {
            SpotlightMapChrome()
        }
        .onAppear {
            let launchDetent = harness.detent(default: .medium)
            detent = launchDetent == .height(120) ? SpotlightRoot.compactDetent : launchDetent
            if let query = Harness.value(after: "-query", in: ProcessInfo.processInfo.arguments) {
                harness.searchText = query
            }
        }
    }
}
