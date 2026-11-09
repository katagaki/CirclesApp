import SwiftUI

struct HubStartRouteButton: View {

    @Environment(Harness.self) var harness

    var body: some View {
        Button {
            withAnimation(.snappy) {
                harness.routeStep = 0
                harness.isNavigating = true
            }
        } label: {
            Label("Start Route", systemImage: "location.north.fill")
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 4.0)
        }
        .buttonStyle(.glassProminent)
        .disabled(harness.routeStops.isEmpty)
    }
}
