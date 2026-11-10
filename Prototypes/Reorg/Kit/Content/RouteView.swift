import SwiftUI

struct RouteView: View {

    @Environment(Harness.self) var harness

    var body: some View {
        List {
            if harness.isNavigating {
                Section {
                    NextStopCard()
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                Section("Stops in \(harness.hall.name)") {
                    ForEach(Array(harness.routeStops.enumerated()), id: \.element.id) { index, stop in
                        RouteStopRow(index: index, circle: stop)
                    }
                }
                Section {
                    Button("End Route", systemImage: "xmark", role: .destructive) { harness.isNavigating = false }
                }
            } else {
                Section {
                    RouteModeButton(title: "Shortest Walk", detail: "Visit every favorite in the fewest steps",
                                    symbol: "point.topleft.down.to.point.bottomright.curvepath")
                    RouteModeButton(title: "By Priority", detail: "Go through your colors in the order you choose",
                                    symbol: "list.number")
                } header: {
                    Text("Start a route through \(harness.routeStops.count) favorites")
                }
            }
        }
        .navigationTitle("Route")
    }
}
