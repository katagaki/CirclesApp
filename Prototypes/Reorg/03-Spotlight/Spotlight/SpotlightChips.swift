import SwiftUI

struct SpotlightChips: View {

    static let features: [Feature] = [.favorites, .buys, .navigation, .sharedBuys, .catalog, .myComiket, .eventData, .settings]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8.0) {
                ForEach(SpotlightChips.features) { feature in
                    NavigationLink(value: feature) {
                        Label(feature.title, systemImage: feature.symbol)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(feature.tint)
                            .padding(.horizontal, 12.0)
                            .frame(height: 34.0)
                            .background(feature.tint.opacity(0.14), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16.0)
        }
        .scrollIndicators(.hidden)
    }
}
