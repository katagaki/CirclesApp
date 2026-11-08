import AXiS
import SwiftUI

/// Asks what a long-pressed spot on the map is: where the visitor is standing, or a path
/// staff have closed. A tapped closure offers to reopen it instead.
struct UnifiedRouteHoldBar: View {

    @Environment(Database.self) var database
    @Environment(Navigator.self) var navigator

    var body: some View {
        Group {
            if navigator.pendingPoint != nil {
                VStack(spacing: 8.0) {
                    HStack {
                        Text("Route.Hold.Title")
                            .font(.subheadline.weight(.semibold))
                        Spacer(minLength: 8.0)
                        Button(role: .close) {
                            navigator.cancelHold()
                        }
                        .buttonStyle(.glass)
                    }
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
                .padding(12.0)
                .glassEffect(.regular, in: .rect(cornerRadius: 22.0))
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if navigator.selectedClosureID != nil {
                bar {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(navigator.selectedClosureIsHallBoundary ? "Route.Closure.Halls.Title" : "Route.Closure.Title")
                            .font(.subheadline.weight(.semibold))
                        Text("Route.Closure.Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4.0)
                    Button {
                        navigator.reopenSelectedClosure(database: database)
                    } label: {
                        Text("Route.Closure.Reopen")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }

    func action(
        _ title: LocalizedStringKey, systemImage: String, tint: Color, perform: @escaping () -> Void
    ) -> some View {
        Button(action: perform) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(tint)
    }

    func bar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8.0) {
            content()
            Spacer(minLength: 0.0)
            Button(role: .close) {
                navigator.cancelHold()
            }
            .buttonStyle(.glass)
        }
        .padding(10.0)
        .glassEffect(.regular, in: .rect(cornerRadius: 22.0))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
