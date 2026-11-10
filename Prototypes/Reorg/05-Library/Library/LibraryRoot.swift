import SwiftUI

struct LibraryRoot: View {

    static let compactDetent: PresentationDetent = .height(280)

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    var body: some View {
        MapStage(detent: $detent, detents: [Self.compactDetent, .medium, .large],
                 sheetMapInset: 280.0, panelWidth: 560.0) {
            LibraryPanel(detent: $detent)
        } chrome: {
            LibraryMapChrome()
        }
        .onAppear {
            detent = harness.launchDetent == "small" ? Self.compactDetent : harness.detent(default: .medium)
        }
    }
}
