import SwiftUI

struct HubRoot: View {

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium
    @State var showsMe = false

    var body: some View {
        MapStage(detent: $detent, detents: [.height(170), .medium, .large], sheetMapInset: 170.0) {
            HubPanel(showsMe: $showsMe)
        } chrome: {
            HubMapChrome(showsMe: $showsMe)
        }
        .onAppear {
            let launchDetent = harness.detent(default: .medium)
            detent = launchDetent == .height(120) ? .height(170) : launchDetent
        }
    }
}
