import SwiftUI

struct UnifiedRouteControls: View {

    let isArrival: Bool
    let canGoBack: Bool
    let canReportBlocked: Bool
    let onBack: () -> Void
    let onBlocked: () -> Void
    let onSkip: () -> Void
    let onVisited: () -> Void

    var body: some View {
        HStack(spacing: 8.0) {
            if canReportBlocked {
                Button(action: onBlocked) {
                    Label("Route.Blocked", systemImage: "arrow.triangle.branch")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.glass)
            }
            Spacer(minLength: 8.0)
            Button("Route.Previous", systemImage: "chevron.backward", action: onBack)
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .disabled(!canGoBack)
            if isArrival {
                Button("Route.Skip", systemImage: "chevron.forward", action: onSkip)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                Button(action: onVisited) {
                    Label("Route.MarkVisited", systemImage: "checkmark")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
            } else {
                Button(action: onSkip) {
                    Label("Route.Next", systemImage: "chevron.forward")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .fixedSize()
                }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
            }
        }
    }
}
