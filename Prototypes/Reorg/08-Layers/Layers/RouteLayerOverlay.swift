import SwiftUI

struct RouteLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var body: some View {
        if !harness.isNavigating {
            HallRouteOverlay(layout: layout)
        }
    }
}
