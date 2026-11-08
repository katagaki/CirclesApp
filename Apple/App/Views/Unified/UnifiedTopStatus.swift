import SwiftUI

/// The badges along the top of the map: offline status on the leading edge, route guidance
/// on the trailing edge. Whichever is expanded takes the row and hides the other.
struct UnifiedTopStatus: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    var isRouteExpanded: Bool {
        navigator.isStatusExpanded || navigator.isNoStopsAlertPresented
    }

    var body: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(alignment: .trailing, spacing: 8.0) {
                if isRouteExpanded {
                    UnifiedRouteStatus(namespace: namespace)
                } else {
                    HStack(alignment: .top, spacing: 8.0) {
                        UnifiedOfflineStatus()
                        if !unifier.isOfflineStatusExpanded {
                            Spacer(minLength: 0.0)
                            UnifiedRouteStatus(namespace: namespace)
                        }
                    }
                }
            }
        }
        .animation(.smooth, value: isRouteExpanded)
    }
}
