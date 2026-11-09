import SwiftUI

struct ModesRoot: View {

    static let goScreens: Set<String> = ["go", "sharedBuys", "navigation"]

    @Environment(Harness.self) var harness
    @State var mode: AppMode = .plan
    @State var detent: PresentationDetent = AppMode.plan.defaultDetent

    var body: some View {
        MapStage(detent: $detent, detents: mode.detents, sheetMapInset: mode == .go ? 210.0 : 150.0) {
            ModesPanel(mode: mode)
        } chrome: {
            ModesMapChrome(mode: $mode)
        }
        .onAppear {
            if let screen = harness.launchScreen, ModesRoot.goScreens.contains(screen) {
                mode = .go
            } else if harness.launchScreen == nil && harness.isNavigating {
                mode = .go
            }
            let launchDetent = harness.detent(default: mode.defaultDetent)
            detent = launchDetent == .height(120) ? mode.smallDetent : launchDetent
        }
        .onChange(of: mode) { _, newMode in
            detent = newMode.defaultDetent
        }
    }
}
