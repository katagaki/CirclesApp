import SwiftUI

struct ToolbeltRailButton: View {

    let tool: ToolbeltTool
    @Binding var selection: ToolbeltTool?
    var isLive: Bool = false

    var body: some View {
        Button {
            selection = selection == tool ? nil : tool
        } label: {
            Image(systemName: tool.symbol)
                .font(.system(size: 18.0, weight: .medium))
                .foregroundStyle(selection == tool ? Color.white : (isLive ? Color.accentColor : Color.primary))
                .frame(width: 40.0, height: 40.0)
                .background(selection == tool ? Color.accentColor : Color.clear, in: .circle)
                .overlay(alignment: .topTrailing) {
                    if isLive && selection != tool {
                        Circle().fill(.green).frame(width: 8.0, height: 8.0).offset(x: -4.0, y: 4.0)
                    }
                }
                .frame(height: 48.0)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.title)
    }
}
