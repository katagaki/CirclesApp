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
                bar {
                    Button {
                        navigator.setOriginAtHold(database: database)
                    } label: {
                        Label("Route.Hold.SetOrigin", systemImage: "figure.walk")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.green)
                    Button {
                        navigator.closePathAtHold(database: database)
                    } label: {
                        Label("Route.Hold.Close", systemImage: "nosign")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                }
            } else if navigator.selectedClosureID != nil {
                bar {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Route.Closure.Title")
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
