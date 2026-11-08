import SwiftUI

/// The badges along the top of the map: offline status on the leading edge, route guidance
/// on the trailing edge. An expanded route card takes the full width on a row of its own.
struct UnifiedTopStatus: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    let namespace: Namespace.ID

    var isRouteExpanded: Bool {
        navigator.isStatusExpanded || navigator.pendingPoint != nil
            || navigator.selectedClosureID != nil || navigator.isNoStopsAlertPresented
    }

    var body: some View {
        GlassEffectContainer(spacing: 8.0) {
            VStack(alignment: .trailing, spacing: 8.0) {
                HStack(alignment: .top, spacing: 8.0) {
                    UnifiedOfflineStatus()
                    if !isRouteExpanded && !unifier.isOfflineStatusExpanded {
                        Spacer(minLength: 0.0)
                        UnifiedRouteStatus(namespace: namespace)
                    }
                }
                if isRouteExpanded {
                    UnifiedRouteStatus(namespace: namespace)
                }
            }
        }
        .animation(.smooth, value: isRouteExpanded)
    }
}
