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
                separator
                row("Route.Hold.Close", systemImage: "nosign", isLast: navigator.hallBoundaries.isEmpty) {
                    navigator.closePathAtHold(database: database)
                }
                if !navigator.hallBoundaries.isEmpty {
                    separator
                    row("Route.Hold.CloseHalls", systemImage: "rectangle.split.2x1", isLast: true) {
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
                row("Route.Closure.Reopen", systemImage: "arrow.uturn.backward", isLast: true) {
                    navigator.reopenSelectedClosure(database: database)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Starts under the row titles rather than the icons, the way a list's separators do.
    var separator: some View {
        Divider()
            .padding(.leading, 28.0)
    }

    /// Rows are padded above and below, except under the last one, where the popover's own
    /// padding already sits.
    func row(
        _ title: LocalizedStringKey, systemImage: String, isLast: Bool = false, perform: @escaping () -> Void
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
            .padding(.top, 10.0)
            .padding(.bottom, isLast ? 0.0 : 10.0)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
