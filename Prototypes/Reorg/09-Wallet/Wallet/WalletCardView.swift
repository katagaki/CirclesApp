import SwiftUI

struct WalletCardView: View {

    let card: WalletCard
    let isExpanded: Bool
    let collapse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            WalletCardHeader(card: card, isExpanded: isExpanded, collapse: collapse)
                .padding(.horizontal, 16.0)
                .frame(height: 50.0)
            if isExpanded {
                WalletCardContent(card: card)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 20.0))
                    .padding([.horizontal, .bottom], 6.0)
                    .transition(.opacity)
            } else {
                WalletCardDetail(card: card)
                    .padding(.horizontal, 16.0)
                    .transition(.opacity)
                Spacer(minLength: 0.0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(card.gradient, in: .rect(cornerRadius: 24.0))
        .overlay(RoundedRectangle(cornerRadius: 24.0).stroke(.white.opacity(0.3), lineWidth: 1.0))
        .contentShape(.rect(cornerRadius: 24.0))
    }
}
