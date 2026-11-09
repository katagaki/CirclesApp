import SwiftUI

struct ToolbeltRail: View {

    @Environment(Harness.self) var harness
    @Binding var tool: ToolbeltTool?
    @Binding var layers: ToolbeltLayers

    var body: some View {
        VStack(spacing: 0.0) {
            ToolbeltDayHallMenu()
            Divider().frame(width: 28.0)
            ToolbeltRailButton(tool: .route, selection: $tool, isLive: harness.isNavigating)
            ToolbeltRailButton(tool: .sharedBuys, selection: $tool, isLive: harness.isSharedBuysActive)
            ToolbeltLayersMenu(layers: $layers)
            Divider().frame(width: 28.0)
            ToolbeltMeButton(selection: $tool)
        }
        .padding(.vertical, 4.0)
        .frame(width: 52.0)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
