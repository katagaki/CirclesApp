import SwiftUI

struct NextStopCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        if let stop = harness.nextStop {
            HStack(spacing: 12.0) {
                CircleCut(circle: stop, size: 44.0)
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("NEXT STOP · \(harness.routeStep + 1) of \(harness.routeStops.count)")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.blue)
                    Text(stop.name).font(.headline).lineLimit(1)
                    SpaceBadge(circle: stop)
                }
                Spacer(minLength: 0.0)
                Button {
                    harness.visited.insert(stop.id)
                    harness.routeStep = min(harness.routeStep + 1, harness.routeStops.count - 1)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .frame(width: 44.0, height: 44.0)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
            }
            .padding(14.0)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 18.0))
        }
    }
}
