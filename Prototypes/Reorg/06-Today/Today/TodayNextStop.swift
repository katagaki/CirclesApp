import SwiftUI

struct TodayNextStop: View {

    @Environment(Harness.self) var harness
    let stop: MockCircle

    var body: some View {
        HStack(spacing: 12.0) {
            NavigationLink(value: stop) {
                HStack(spacing: 12.0) {
                    CircleCut(circle: stop, size: 40.0)
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text(stop.name).font(.headline).lineLimit(1)
                        HStack(spacing: 6.0) {
                            SpaceBadge(circle: stop)
                            Text("Stop \(harness.routeStep + 1) of \(harness.routeStops.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0.0)
            Button {
                harness.visited.insert(stop.id)
                harness.routeStep = min(harness.routeStep + 1, harness.routeStops.count - 1)
            } label: {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
                    .frame(width: 40.0, height: 40.0)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
        }
    }
}
