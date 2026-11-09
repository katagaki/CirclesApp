import SwiftUI

struct WalletTuckedDeck: View {

    let expanded: WalletCard
    let namespace: Namespace.ID
    let select: (WalletCard?) -> Void

    var others: [WalletCard] { WalletCard.allCases.filter { $0 != expanded } }

    var body: some View {
        HStack(spacing: 6.0) {
            ForEach(others) { card in
                Button {
                    select(card)
                } label: {
                    Image(systemName: card.symbol)
                        .font(.system(size: 15.0, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 40.0)
                        .background(card.gradient, in: .rect(cornerRadius: 12.0))
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: card, in: namespace)
                .accessibilityLabel(card.title)
            }
        }
        .padding(6.0)
        .background(Color(uiColor: .tertiarySystemFill), in: .rect(cornerRadius: 18.0))
    }
}
