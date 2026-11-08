import SwiftUI

/// The badges along the top of the map: offline status on the leading edge, route guidance
/// on the trailing edge. Whichever is expanded takes the row and hides the other.
struct UnifiedTopStatus: View {

    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier

    var isRouteExpanded: Bool {
        navigator.isStatusExpanded || navigator.isNoStopsAlertPresented
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
    }
}
