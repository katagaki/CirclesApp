import SwiftUI

/// Route guidance at the top trailing edge of the map, built like the offline badge: a pill
/// that grows into the full directions below it when tapped, and shrinks back again.
struct UnifiedRouteStatus: View {

    @Environment(Navigator.self) var navigator

    var isVisible: Bool {
        navigator.isActive || navigator.isNoStopsAlertPresented
    }

    var isExpanded: Bool {
        navigator.isStatusExpanded
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
                                    navigator.dismissNoStops()
                                }
                            } else if navigator.isTrapped {
                                UnifiedRouteTrappedSection()
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
            HStack(spacing: 8.0) {
                UnifiedRoutePill()
                if isExpanded {
                    Spacer(minLength: 0.0)
                    Image(systemName: "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Route.Collapse"))
                }
            }
                .padding(.horizontal, isExpanded ? 14.0 : 10.0)
                .padding(.vertical, isExpanded ? 10.0 : 7.0)
                .contentShape(.rect.inset(by: -8.0))
        }
        .buttonStyle(.plain)
    }
}
