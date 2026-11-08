import SwiftUI

/// Route guidance at the top trailing edge of the map, built like the offline badge: a pill
/// that grows into the full directions below it when tapped, and shrinks back again.
struct UnifiedRouteStatus: View {

    @Environment(Navigator.self) var navigator

    var isVisible: Bool {
        navigator.isActive || navigator.isNoStopsAlertPresented
    }

    var isExpanded: Bool {
        navigator.isStatusExpanded || navigator.isNoStopsAlertPresented
    }

    var body: some View {
        Group {
            if isVisible {
                VStack(alignment: .leading, spacing: 0.0) {
                    pill
                    if isExpanded {
                        Group {
                            if navigator.isNoStopsAlertPresented {
                                UnifiedRouteNoStopsCard {
                                    withAnimation(.smooth.speed(2.0)) {
                                        navigator.isNoStopsAlertPresented = false
                                    }
                                }
                            } else {
                                UnifiedRouteStepSection()
                            }
                        }
                        .padding(.horizontal, 14.0)
                        .padding(.top, 2.0)
                        .padding(.bottom, 14.0)
                    }
                }
                .glassEffect(
                    isExpanded ? .regular : .regular.interactive(),
                    in: .rect(cornerRadius: isExpanded ? 22.0 : 16.0)
                )
                .contentShape(.rect)
                .geometryGroup()
                .frame(maxWidth: isExpanded ? .infinity : nil, alignment: .trailing)
                .transition(.scale(scale: 0.6, anchor: .trailing).combined(with: .opacity))
            }
        }
        .animation(.smooth.speed(2.0), value: isVisible)
    }

    var pill: some View {
        Button {
            withAnimation(.smooth.speed(2.0)) {
                navigator.isStatusExpanded.toggle()
            }
        } label: {
            UnifiedRoutePill()
                .padding(.horizontal, isExpanded ? 14.0 : 10.0)
                .padding(.vertical, isExpanded ? 10.0 : 7.0)
                .contentShape(.rect.inset(by: -8.0))
        }
        .buttonStyle(.plain)
    }
}
