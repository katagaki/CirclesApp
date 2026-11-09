import SwiftUI

struct HallRouteOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var body: some View {
        let stops = harness.routeStops
        ZStack {
            Path { path in
                var current = layout.entrance
                path.move(to: current)
                for stop in stops {
                    let aisle = layout.aislePoint(for: stop)
                    path.addLine(to: CGPoint(x: current.x, y: aisle.y))
                    path.addLine(to: aisle)
                    current = aisle
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4.0, lineCap: .round, lineJoin: .round))
            .shadow(color: .blue.opacity(0.3), radius: 4.0)
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                HallRouteStopBadge(number: index + 1, isNext: index == harness.routeStep, isDone: index < harness.routeStep)
                    .position(layout.aislePoint(for: stop))
            }
        }
    }
}
