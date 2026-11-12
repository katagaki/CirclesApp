import SwiftUI

struct UnifiedToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    var body: some ToolbarContent {
        if !oasis.isShowing && !authenticator.isAuthenticating {
            ToolbarItem(placement: .topBarLeading) {
                UnifiedControl()
                    .fixedSize()
                    .foregroundStyle(.primary)
                    .glassEffect(.regular.interactive())
                    .adaptiveShadow()
                    .opacity(unifier.presentedControlMenu == nil ? 1.0 : 0.0)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        ToolbarItem(placement: .topBarTrailing) {
            MyComiketButton()
        }
        .sharedBackgroundVisibility(.hidden)
        if unifier.displayMode == .sheet {
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button("Shared.OpenPanel", systemImage: "chevron.up") {
                    unifier.show()
                }
                .opacity(unifier.isPresenting ? 0.0 : 1.0)
                .disabled(unifier.isPresenting)
                .animation(.easeInOut(duration: 0.2), value: unifier.isPresenting)
            }
            .matchedTransitionSource(id: "BottomPanel", in: namespace)
            .sharedBackgroundVisibility(unifier.isPresenting ? .hidden : .visible)
        }
    }
}
