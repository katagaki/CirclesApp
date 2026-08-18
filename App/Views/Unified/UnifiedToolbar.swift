import SwiftUI

struct UnifiedToolbar: ToolbarContent {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    var body: some ToolbarContent {
        @Bindable var unifier = unifier
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
                    .popover(isPresented: $unifier.isOfflineModeTipShowing, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 8.0) {
                            Text("Alerts.OfflineMode.Tip.Title")
                                .font(.headline)
                            Text("Alerts.OfflineMode.Tip.Message")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(idealWidth: 320.0)
                        .presentationCompactAdaptation(.popover)
                    }
            }
        }
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
        }
    }
}
