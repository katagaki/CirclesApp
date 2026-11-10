import SwiftUI

struct RouteStopRow: View {

    @Environment(Harness.self) var harness
    let index: Int
    let circle: MockCircle

    var body: some View {
        HStack(spacing: 12.0) {
            HallRouteStopBadge(number: index + 1, isNext: false, isDone: index < harness.routeStep)
            CircleCut(circle: circle, size: 26.0)
            VStack(alignment: .leading, spacing: 2.0) {
                Text(circle.name).font(.subheadline.weight(.medium))
                Text(circle.spaceName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if index == harness.routeStep {
                Text("NEXT").font(.caption2.weight(.heavy)).foregroundStyle(.blue)
            }
        }
        .opacity(index < harness.routeStep ? 0.5 : 1.0)
    }
}
