import SwiftUI

struct TodayStartRoute: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(spacing: 12.0) {
            VStack(alignment: .leading, spacing: 2.0) {
                Text("Start your route").font(.headline)
                Text("\(harness.routeStops.count) favorites in \(harness.hall.name), shortest walk first")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
            Button("Start") {
                harness.routeStep = 0
                harness.isNavigating = true
            }
            .buttonStyle(.glassProminent)
            .disabled(harness.routeStops.isEmpty)
        }
    }
}
