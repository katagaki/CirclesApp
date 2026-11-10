import SwiftUI

struct VisitedLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var body: some View {
        ZStack {
            ForEach(MockData.circles.filter { $0.hall == harness.hall && harness.visited.contains($0.id) }) { circle in
                LayerMarker(symbol: "checkmark", tint: .green)
                    .position(layout.point(for: circle))
            }
        }
    }
}
