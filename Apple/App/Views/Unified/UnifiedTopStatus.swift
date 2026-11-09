import SwiftUI

/// The offline badge along the top of the map. It reports its collapsed height so the map
/// can keep its content clear of it.
struct UnifiedTopStatus: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Unifier.self) var unifier

    @State var collapsedHeight: CGFloat = 0.0

    var isVisible: Bool {
        authenticator.effectiveOnlineState == .offline
            && !authenticator.isAuthenticating && !oasis.isShowing
    }

    var inset: CGFloat {
        isVisible ? collapsedHeight + 8.0 : 0.0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8.0) {
            UnifiedOfflineStatus()
            if !unifier.isOfflineStatusExpanded {
                Spacer(minLength: 0.0)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            if !unifier.isOfflineStatusExpanded && newValue > 0.0 {
                collapsedHeight = newValue
            }
        }
        .onChange(of: inset, initial: true) { _, newValue in
            unifier.topStatusInset = newValue
        }
    }
}
