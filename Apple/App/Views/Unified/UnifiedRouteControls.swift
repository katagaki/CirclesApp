import SwiftUI

/// Detour, back and forward keep the same place on every step, so they can be tapped
/// without looking; only the visited button comes and goes, at the leading edge.
struct UnifiedRouteControls: View {

    let isArrival: Bool
    let canGoBack: Bool
    let canReportBlocked: Bool
    var canGoForward: Bool = true
    let onBack: () -> Void
    let onBlocked: () -> Void
    let onSkip: () -> Void
    let onVisited: () -> Void

    let buttonHeight: CGFloat = 26.0

    var body: some View {
        HStack(spacing: 8.0) {
            if isArrival {
                Button(action: onVisited) {
                    Label("Route.MarkVisited", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .fixedSize()
                        .frame(height: buttonHeight)
                        .padding(.horizontal, 4.0)
                }
                .buttonStyle(.glassProminent)
                .tint(.accentColor)
            }
            Spacer(minLength: 0.0)
            Button(action: onBlocked) {
                Text("Route.Blocked")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .frame(height: buttonHeight)
                    .padding(.horizontal, 4.0)
            }
            .buttonStyle(.glass)
            .opacity(canReportBlocked ? 1.0 : 0.0)
            .disabled(!canReportBlocked)
            .accessibilityHidden(!canReportBlocked)
            Button(action: onBack) {
                Image(systemName: "chevron.backward")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: buttonHeight, height: buttonHeight)
            }
            .accessibilityLabel("Route.Previous")
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .disabled(!canGoBack)
            Button(action: onSkip) {
                Image(systemName: "chevron.forward")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: buttonHeight, height: buttonHeight)
            }
            .accessibilityLabel(isArrival ? "Route.Skip" : "Route.Next")
            .buttonStyle(.glass)
            .disabled(!canGoForward)
            .buttonBorderShape(.circle)
        }
    }
}
