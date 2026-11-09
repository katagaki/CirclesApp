import SwiftUI

struct WalletStack: View {

    let namespace: Namespace.ID
    let select: (WalletCard?) -> Void

    static let cardHeight: CGFloat = 156.0

    var body: some View {
        GeometryReader { proxy in
            let others = CGFloat(WalletCard.allCases.count - 1)
            let strip = proxy.size.height < 300.0 ? 38.0 : max(54.0, min(80.0, (proxy.size.height - 40.0 - Self.cardHeight) / others))
            ScrollView {
                VStack(spacing: 12.0) {
                    GuestBanner()
                    VStack(spacing: strip - Self.cardHeight) {
                        ForEach(WalletCard.allCases) { card in
                            WalletCardView(card: card, isExpanded: false, collapse: { select(nil) })
                                .frame(height: Self.cardHeight)
                                .matchedGeometryEffect(id: card, in: namespace)
                                .shadow(color: .black.opacity(0.18), radius: 6.0, y: -2.0)
                                .onTapGesture { select(card) }
                        }
                    }
                }
                .padding(.horizontal, 16.0)
                .padding(.top, 20.0)
                .padding(.bottom, 16.0)
            }
        }
    }
}
