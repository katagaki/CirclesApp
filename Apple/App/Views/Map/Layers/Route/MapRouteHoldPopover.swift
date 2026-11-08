import AXiS
import SwiftUI

/// What a long-pressed spot is: where the visitor is standing, or a way that is closed.
/// A tapped closure offers to reopen it instead.
struct MapRouteHoldPopover: View {

    @Environment(Database.self) var database
    @Environment(Navigator.self) var navigator

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            if navigator.pendingPoint != nil {
                Text("Route.Hold.Title")
                    .font(.body.weight(.semibold))
                    .padding(.bottom, 2.0)
                row("Route.Hold.SetOrigin", systemImage: "figure.walk") {
                    navigator.setOriginAtHold(database: database)
                }
                Divider()
                row("Route.Hold.Close", systemImage: "nosign",
                    bottom: navigator.hallBoundaries.isEmpty ? 0.0 : 5.0) {
                    navigator.closePathAtHold(database: database)
                }
                if !navigator.hallBoundaries.isEmpty {
                    row("Route.Hold.CloseHalls", systemImage: "rectangle.split.2x1", top: 5.0, bottom: 0.0) {
                        navigator.closeHallsAtHold(database: database)
                    }
                }
            } else {
                Text(navigator.selectedClosureIsHallBoundary ? "Route.Closure.Halls.Title" : "Route.Closure.Title")
                    .font(.body.weight(.semibold))
                Text("Route.Closure.Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6.0)
                Divider()
                row("Route.Closure.Reopen", systemImage: "arrow.uturn.backward", bottom: 0.0) {
                    navigator.reopenSelectedClosure(database: database)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// A row sits 10 points from a divider on either side. Under the last row the popover's
    /// own padding takes over, and rows in the same group sit as close to each other as a
    /// row sits to a divider, so the group reads as one.
    func row(
        _ title: LocalizedStringKey, systemImage: String, top: CGFloat = 10.0, bottom: CGFloat = 10.0,
        perform: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.smooth) {
                perform()
            }
        } label: {
            HStack(spacing: 6.0) {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 22.0)
                Text(title)
                Spacer(minLength: 0.0)
            }
            .font(.body)
            .padding(.top, top)
            .padding(.bottom, bottom)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
