import SwiftUI

struct WalletExpandedLayout: View {

    let expanded: WalletCard
    let namespace: Namespace.ID
    let select: (WalletCard?) -> Void

    var body: some View {
        VStack(spacing: 10.0) {
            WalletCardView(card: expanded, isExpanded: true, collapse: { select(nil) })
                .frame(maxHeight: .infinity)
                .matchedGeometryEffect(id: expanded, in: namespace)
                .zIndex(1.0)
            WalletTuckedDeck(expanded: expanded, namespace: namespace, select: select)
        }
        .padding(.horizontal, 12.0)
        .padding(.top, 14.0)
        .padding(.bottom, 8.0)
    }
}
