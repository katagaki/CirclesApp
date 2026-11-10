import SwiftUI

struct LayersRoot: View {

    @Environment(Harness.self) var harness
    @State var layers = LayersState()
    @State var detent: PresentationDetent = .medium

    var body: some View {
        LayersStage(detent: $detent, detents: [.height(150), .medium, .large], sheetMapInset: 150.0) {
            LayersPanel()
        } chrome: {
            LayersMapChrome()
        } overlay: { layout in
            LayersMapOverlay(layout: layout)
        }
        .environment(layers)
        .onAppear {
            let launchDetent = harness.detent(default: .medium)
            detent = launchDetent == .height(120) ? .height(150) : launchDetent
            if harness.isNavigating {
                layers.show(.route)
            }
            if let screen = harness.launchScreen, let layer = MapLayer(rawValue: screen) {
                layers.show(layer)
            }
        }
        .onChange(of: harness.isNavigating) { _, isNavigating in
            if isNavigating {
                layers.show(.route)
            }
        }
    }
}
