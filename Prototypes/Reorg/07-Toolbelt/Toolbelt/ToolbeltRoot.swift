import SwiftUI

struct ToolbeltRoot: View {

    static let compactDetent: PresentationDetent = .height(150)

    @Environment(Harness.self) var harness
    @State var detent: PresentationDetent = .medium
    @State var tool: ToolbeltTool?
    @State var toolPath: [Feature] = []
    @State var layers = ToolbeltLayers()

    var body: some View {
        MapStage(detent: $detent, detents: [Self.compactDetent, .medium, .large], sheetMapInset: 150.0) {
            ToolbeltPanel(tool: $tool, toolPath: $toolPath, detent: $detent)
        } chrome: {
            ToolbeltMapChrome(tool: $tool, layers: $layers)
        }
        .onAppear {
            detent = harness.launchDetent == "small" ? Self.compactDetent : harness.detent(default: .medium)
            switch harness.launchScreen {
            case "myComiket", "eventData", "settings":
                tool = .me
                toolPath = harness.launchScreen.flatMap(Feature.init(rawValue:)).map { [$0] } ?? []
            case let screen?:
                tool = ToolbeltTool(rawValue: screen)
            case nil:
                break
            }
        }
        .onChange(of: tool) { _, newTool in
            if newTool == nil { toolPath = [] }
            if newTool != nil && detent == Self.compactDetent { detent = .medium }
        }
    }
}
