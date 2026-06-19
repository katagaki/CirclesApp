import SwiftUI

struct UnifiedToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Tab.My", image: .buttonMy) {
                unifier.hide()
                unifier.isMyComiketPresenting = true
            }
            .matchedTransitionSource(id: "My.View", in: namespace)
        }
        if !oasis.isShowing && !authenticator.isAuthenticating {
            ToolbarItem(placement: .principal) {
                UnifiedControl()
                    .foregroundStyle(.primary)
                    .glassEffect(.regular.interactive())
                    .adaptiveShadow()
            }
            ToolbarItem(placement: .topBarTrailing) {
                UnifiedMoreMenu()
            }
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("Shared.OpenPanel", systemImage: "chevron.up") {
                    unifier.show()
                }
            }
            .matchedTransitionSource(id: "BottomPanel", in: namespace)
        }
    }
}
