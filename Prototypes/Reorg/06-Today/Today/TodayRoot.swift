import SwiftUI

struct TodayRoot: View {

    static let compactDetent: PresentationDetent = .height(250)

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    var body: some View {
        MapStage(detent: $detent, detents: [Self.compactDetent, .medium, .large], sheetMapInset: 250.0) {
            TodayPanel(detent: $detent)
        } chrome: {
            TodayMapChrome()
        }
        .onAppear {
            detent = harness.launchDetent == "small" ? Self.compactDetent : harness.detent(default: .medium)
        }
    }
}
