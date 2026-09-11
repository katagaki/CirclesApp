import SwiftUI

struct UnifiedQuickAccessBar: View {

    @Environment(Unifier.self) var unifier

    var body: some View {
        Button {
            unifier.requestSearch()
        } label: {
            HStack(spacing: 8.0) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                Text("Circles.Search.Prompt")
                    .lineLimit(1)
                Spacer(minLength: 0.0)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14.0)
            .frame(maxWidth: .infinity, minHeight: 48.0)
            .quickAccessBackground(in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isSearchField)
        .padding(.horizontal, 20.0)
        .padding(.top, 20.0)
        .padding(.bottom, 20.0)
    }
}

fileprivate extension View {
    @ViewBuilder
    func quickAccessBackground(in shape: some Shape) -> some View {
        if #available(iOS 27.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(Color(uiColor: .tertiarySystemFill), in: shape)
        }
    }
}
