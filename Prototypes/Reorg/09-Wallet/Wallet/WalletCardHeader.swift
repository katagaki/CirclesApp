import SwiftUI

struct WalletCardHeader: View {

    let card: WalletCard
    let isExpanded: Bool
    let collapse: () -> Void

    var body: some View {
        HStack(spacing: 10.0) {
            Image(systemName: card.symbol)
                .font(.system(size: 15.0, weight: .bold))
                .frame(width: 30.0, height: 30.0)
                .background(.white.opacity(0.22), in: .circle)
            Text(card.title)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 8.0)
            WalletCardSummary(card: card)
            if isExpanded {
                Button(action: collapse) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14.0, weight: .bold))
                        .frame(width: 30.0, height: 30.0)
                        .background(.white.opacity(0.25), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Collapse")
            }
        }
        .foregroundStyle(.white)
    }
}
