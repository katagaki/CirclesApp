import SwiftUI

struct GoLinkRow: View {

    let feature: Feature
    let title: String

    var body: some View {
        NavigationLink(value: feature) {
            HStack {
                Label(title, systemImage: feature.symbol)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
