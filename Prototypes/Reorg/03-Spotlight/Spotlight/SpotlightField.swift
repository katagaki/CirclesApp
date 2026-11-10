import SwiftUI

struct SpotlightField: View {

    @Environment(Harness.self) var harness

    var body: some View {
        @Bindable var harness = harness
        HStack(spacing: 10.0) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tint)
            TextField("Search anything", text: $harness.searchText)
                .font(.title3)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !harness.searchText.isEmpty {
                Button {
                    harness.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            NavigationLink(value: Feature.myComiket) {
                ProfileAvatar(size: 32.0)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16.0)
        .padding(.trailing, 8.0)
        .frame(height: 52.0)
        .background(Color(uiColor: .tertiarySystemFill), in: .capsule)
        .padding(.horizontal, 16.0)
    }
}
