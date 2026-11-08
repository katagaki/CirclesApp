import SwiftUI

/// The badges along the top of the map: offline status on the leading edge, route guidance
/// on the trailing edge. Whichever is expanded takes the row and hides the other.
struct UnifiedTopStatus: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(Oasis.self) var oasis
    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    @State var collapsedHeight: CGFloat = 0.0

    var isRouteExpanded: Bool {
        navigator.isStatusExpanded
    }

    var isAnyVisible: Bool {
        let isOfflineVisible = authenticator.effectiveOnlineState == .offline
            && !authenticator.isAuthenticating && !oasis.isShowing
        return isOfflineVisible || navigator.isActive || navigator.isNoStopsAlertPresented
    }

    var isAnyExpanded: Bool {
        isRouteExpanded || unifier.isOfflineStatusExpanded
    }

    var inset: CGFloat {
        isAnyVisible ? collapsedHeight + 8.0 : 0.0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8.0) {
            if !isRouteExpanded {
                UnifiedOfflineStatus()
            }
            if !unifier.isOfflineStatusExpanded {
                if !isRouteExpanded {
                    Spacer(minLength: 0.0)
                }
                UnifiedRouteStatus()
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newValue in
            if !isAnyExpanded && newValue > 0.0 {
                collapsedHeight = newValue
            }
        }
        .onChange(of: inset, initial: true) { _, newValue in
            unifier.topStatusInset = newValue
        }
    }
}
