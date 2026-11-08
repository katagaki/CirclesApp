import SwiftUI

/// Shown in place of the route card, since the panel is a sheet and an alert from the map
/// behind it cannot be presented.
struct UnifiedRouteNoStopsCard: View {

    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack(alignment: .top, spacing: 10.0) {
                Image(systemName: "heart.slash")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("Route.NoStops.Title")
                        .font(.headline)
                    Text("Route.NoStops.Message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0.0)
            }
            HStack {
                Spacer()
                Button(role: .confirm, action: onDismiss)
                    .buttonStyle(.glassProminent)
            }
        }
        .padding(14.0)
        .glassEffect(.regular, in: .rect(cornerRadius: 22.0))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
