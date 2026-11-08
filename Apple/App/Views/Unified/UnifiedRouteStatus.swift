import SwiftUI

/// Route guidance at the top trailing edge of the map. Collapsed, it is a pill with the
/// next turn and the stop; expanded, the pill grows into the full directions.
struct UnifiedRouteStatus: View {

    @Environment(Navigator.self) var navigator

    let namespace: Namespace.ID

    var isVisible: Bool {
        navigator.isActive || navigator.isNoStopsAlertPresented
    }

    var isExpanded: Bool {
        navigator.isStatusExpanded || navigator.isNoStopsAlertPresented
    }

    var body: some View {
        if isVisible {
            if isExpanded {
                VStack(alignment: .leading, spacing: 12.0) {
                    if navigator.isNoStopsAlertPresented {
                        UnifiedRouteNoStopsCard {
                            withAnimation(.smooth) {
                                navigator.isNoStopsAlertPresented = false
                            }
                        }
                    } else if navigator.route != nil {
                        UnifiedRouteStepSection()
                    } else if navigator.isPlanning {
                        UnifiedRoutePill()
                    }
                }
                .padding(14.0)
                .glassEffect(.regular, in: .rect(cornerRadius: 22.0))
                .glassEffectID("RouteStatus", in: namespace)
            } else {
                Button {
                    withAnimation(.smooth) {
                        navigator.isStatusExpanded = true
                    }
                } label: {
                    UnifiedRoutePill()
                        .padding(.horizontal, 10.0)
                        .padding(.vertical, 7.0)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .glassEffectID("RouteStatus", in: namespace)
            }
        }
    }
}
