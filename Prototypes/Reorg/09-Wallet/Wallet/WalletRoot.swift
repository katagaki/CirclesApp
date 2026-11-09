import SwiftUI

struct WalletRoot: View {

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    static let compactDetent: PresentationDetent = .height(220)

    var body: some View {
        MapStage(detent: $detent, detents: [Self.compactDetent, .medium, .large], sheetMapInset: 220.0) {
            WalletPanel(detent: $detent)
        } chrome: {
            WalletMapChrome()
        }
        .onAppear {
            let launchDetent = harness.detent(default: harness.launchScreen == nil ? .medium : .large)
            detent = launchDetent == .height(120) ? Self.compactDetent : launchDetent
        }
    }
}
