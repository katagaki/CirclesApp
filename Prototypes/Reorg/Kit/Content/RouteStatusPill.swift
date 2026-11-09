import SwiftUI

struct RouteStatusPill: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if harness.isNavigating, let stop = harness.nextStop {
            HStack(spacing: 8.0) {
                Image(systemName: "location.north.fill").foregroundStyle(.blue)
                Text(stop.spaceName).font(.subheadline.weight(.semibold).monospacedDigit())
                Text("\(harness.routeStep + 1)/\(harness.routeStops.count)").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12.0)
            .frame(height: 36.0)
            .glassEffect(.regular, in: .capsule)
        }
    }
}
