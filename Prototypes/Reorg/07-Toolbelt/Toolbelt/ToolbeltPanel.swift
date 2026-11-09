import SwiftUI

struct ToolbeltPanel: View {

    @Binding var tool: ToolbeltTool?
    @Binding var toolPath: [Feature]
    @Binding var detent: PresentationDetent

    var body: some View {
        Group {
            if let current = tool {
                ToolbeltToolScreen(tool: current, path: $toolPath) {
                    tool = nil
                }
            } else {
                ToolbeltBrowser(detent: $detent)
            }
        }
        .animation(.snappy, value: tool)
    }
}
