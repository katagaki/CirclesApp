import AXiS
import SwiftUI

/// What a long-pressed spot on the map is: where the visitor is standing, or a way that is
/// closed. A tapped closure offers to reopen it instead.
struct UnifiedRouteHoldSection: View {

    @Environment(Database.self) var database
    @Environment(Navigator.self) var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack {
                if navigator.pendingPoint != nil {
                    Text("Route.Hold.Title")
                        .font(.subheadline.weight(.semibold))
                } else {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(navigator.selectedClosureIsHallBoundary ? "Route.Closure.Halls.Title" : "Route.Closure.Title")
                            .font(.subheadline.weight(.semibold))
                        Text("Route.Closure.Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8.0)
                Button(role: .close) {
                    withAnimation(.smooth) {
                        navigator.cancelHold()
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
            if navigator.pendingPoint != nil {
                HStack(spacing: 8.0) {
                    action("Route.Hold.SetOrigin", systemImage: "figure.walk", tint: .green) {
                        navigator.setOriginAtHold(database: database)
                    }
                    action("Route.Hold.Close", systemImage: "nosign", tint: .red) {
                        navigator.closePathAtHold(database: database)
                    }
                    if !navigator.hallBoundaries.isEmpty {
                        action("Route.Hold.CloseHalls", systemImage: "rectangle.split.2x1", tint: .orange) {
                            navigator.closeHallsAtHold(database: database)
                        }
                    }
                }
            } else {
                Button {
                    navigator.reopenSelectedClosure(database: database)
                } label: {
                    Text("Route.Closure.Reopen")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
    }

    func action(
        _ title: LocalizedStringKey, systemImage: String, tint: Color, perform: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.smooth) {
                perform()
            }
        } label: {
            VStack(spacing: 4.0) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 44.0)
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
    }
}
