import SwiftUI

struct TodayRouteCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        TodayCard(title: harness.isNavigating ? "Next Stop" : "Route", symbol: Feature.navigation.symbol,
                  tint: .blue, destination: .navigation) {
            if harness.isNavigating, let stop = harness.nextStop {
                TodayNextStop(stop: stop)
            } else {
                TodayStartRoute()
            }
        }
    }
}
