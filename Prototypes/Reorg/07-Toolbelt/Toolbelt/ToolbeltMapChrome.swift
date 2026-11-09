import SwiftUI

struct ToolbeltMapChrome: View {

    @Environment(\.stageStyle) var stageStyle
    @Binding var tool: ToolbeltTool?
    @Binding var layers: ToolbeltLayers

    var body: some View {
        ZStack(alignment: .topLeading) {
            if !layers.isDefault {
                ToolbeltLayerOverlay(layers: layers)
                    .padding(.top, 56.0)
                    .padding(.bottom, stageStyle == .sheet ? 150.0 : 0.0)
                    .padding(.leading, stageStyle == .panel ? -12.0 : 0.0)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8.0) {
                    OfflinePill()
                    RouteStatusPill()
                }
                Spacer(minLength: 8.0)
                ToolbeltRail(tool: $tool, layers: $layers)
            }
            .padding(.horizontal, 16.0)
            .padding(.top, 4.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
