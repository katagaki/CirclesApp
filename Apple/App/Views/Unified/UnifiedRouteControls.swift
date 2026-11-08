import SwiftUI

struct UnifiedRouteControls: View {

    let isArrival: Bool
    let canGoBack: Bool
    let canReportBlocked: Bool
    let onBack: () -> Void
    let onBlocked: () -> Void
    let onNext: () -> Void

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
                .tint(.red)
            }
            Spacer(minLength: 8.0)
            Button("Route.Previous", systemImage: "chevron.backward", action: onBack)
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .disabled(!canGoBack)
            Button(action: onNext) {
                Label(isArrival ? "Route.MarkVisited" : "Route.Next",
                      systemImage: isArrival ? "checkmark" : "chevron.forward")
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(.glassProminent)
            .tint(isArrival ? .red : .accentColor)
        }
    }
}
