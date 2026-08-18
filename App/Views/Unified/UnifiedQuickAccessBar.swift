import SwiftUI

struct UnifiedQuickAccessBar: View {

    @Environment(Unifier.self) var unifier

    var body: some View {
        HStack(spacing: 10.0) {
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

            Button {
                unifier.expand()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 15.0, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 48.0, height: 48.0)
                    .quickAccessBackground(in: .circle)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shared.OpenPanel")
        }
        .padding(.horizontal, 20.0)
        .padding(.top, 20.0)
        .padding(.bottom, 20.0)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            unifier.updateCompactBarHeight(newValue)
        }
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
