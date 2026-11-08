import SwiftUI

struct UnifiedRouteControls: View {

    let progress: String
    let isArrival: Bool
    let canGoBack: Bool
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 8.0) {
            Text(progress)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer(minLength: 8.0)
            Button("Route.Previous", systemImage: "chevron.backward", action: onBack)
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .disabled(!canGoBack)
            Button(action: onNext) {
                Label(isArrival ? "Route.MarkVisited" : "Route.Next",
                      systemImage: isArrival ? "checkmark" : "chevron.forward")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.glassProminent)
            .tint(isArrival ? .red : .accentColor)
        }
    }
}
