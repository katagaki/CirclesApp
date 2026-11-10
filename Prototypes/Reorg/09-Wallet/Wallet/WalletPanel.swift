import SwiftUI

struct WalletPanel: View {

    @Environment(Harness.self) var harness
    @Binding var detent: PresentationDetent
    @State var expanded: WalletCard?
    @State var path = NavigationPath()
    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if let expanded {
                    WalletExpandedLayout(expanded: expanded, namespace: namespace, select: select)
                } else {
                    WalletStack(namespace: namespace, select: select)
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .featureDestinations()
        }
        .onAppear {
            if let screen = harness.launchScreen, let card = WalletCard(screen: screen) {
                expanded = card
            }
        }
    }

    func select(_ card: WalletCard?) {
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            expanded = card
        }
        if card != nil && detent == WalletRoot.compactDetent {
            detent = .medium
        }
    }
}
