import SwiftUI

struct SearchField: View {

    @Environment(Harness.self) var harness
    var prompt: String = "Search circles, spaces, genres"

    var body: some View {
        @Bindable var harness = harness
        HStack(spacing: 8.0) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $harness.searchText)
                .textFieldStyle(.plain)
            if !harness.searchText.isEmpty {
                Button {
                    harness.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14.0)
        .frame(height: 44.0)
        .background(Color(uiColor: .tertiarySystemFill), in: .capsule)
    }
}
