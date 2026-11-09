import SwiftUI

struct ToolbeltMeButton: View {

    @Binding var selection: ToolbeltTool?

    var body: some View {
        Button {
            selection = selection == .me ? nil : .me
        } label: {
            ProfileAvatar(size: 34.0)
                .padding(3.0)
                .overlay(Circle().stroke(selection == .me ? Color.accentColor : Color.clear, lineWidth: 2.0))
                .frame(height: 50.0)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Me")
    }
}
