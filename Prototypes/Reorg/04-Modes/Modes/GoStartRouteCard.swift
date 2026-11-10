import SwiftUI

struct GoStartRouteCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(spacing: 12.0) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 36.0))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2.0) {
                Text("Ready to go").font(.headline)
                Text("\(harness.routeStops.count) favorites in \(harness.hall.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
            Button("Start") {
                harness.routeStep = 1
                harness.isNavigating = true
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(14.0)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18.0))
    }
}
