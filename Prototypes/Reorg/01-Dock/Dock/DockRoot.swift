import SwiftUI

struct DockRoot: View {

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium

    var body: some View {
        MapStage(detent: $detent, detents: [.height(170), .medium, .large], sheetMapInset: 170.0) {
            DockPanel()
        } chrome: {
            DockMapChrome()
        }
        .onAppear { detent = harness.detent(default: .medium) }
    }
}
