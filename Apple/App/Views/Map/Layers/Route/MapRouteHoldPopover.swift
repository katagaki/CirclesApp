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
                    .font(.subheadline.weight(.semibold))
                    .padding(.bottom, 6.0)
                row("Route.Hold.SetOrigin", systemImage: "figure.walk") {
                    navigator.setOriginAtHold(database: database)
                }
                Divider()
                row("Route.Hold.Close", systemImage: "nosign") {
                    navigator.closePathAtHold(database: database)
                }
                if !navigator.hallBoundaries.isEmpty {
                    Divider()
                    row("Route.Hold.CloseHalls", systemImage: "rectangle.split.2x1") {
                        navigator.closeHallsAtHold(database: database)
                    }
                }
            } else {
                Text(navigator.selectedClosureIsHallBoundary ? "Route.Closure.Halls.Title" : "Route.Closure.Title")
                    .font(.subheadline.weight(.semibold))
                Text("Route.Closure.Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6.0)
                Divider()
                row("Route.Closure.Reopen", systemImage: "arrow.uturn.backward") {
                    navigator.reopenSelectedClosure(database: database)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    func row(_ title: LocalizedStringKey, systemImage: String, perform: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.smooth) {
                perform()
            }
        } label: {
            HStack(spacing: 10.0) {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 22.0)
                Text(title)
                Spacer(minLength: 0.0)
            }
            .font(.subheadline)
            .frame(minHeight: 40.0)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
