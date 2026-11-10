import SwiftUI

struct BuysLayerOverlay: View {

    @Environment(Harness.self) var harness
    let layout: HallMapLayout

    var circlesWithBuys: [(MockCircle, Int)] {
        Dictionary(grouping: harness.buys.filter { !$0.isBought }, by: \.circleID)
            .compactMap { id, items in MockData.circle(id).map { ($0, items.count) } }
            .filter { $0.0.hall == harness.hall }
    }

    var body: some View {
        ZStack {
            ForEach(circlesWithBuys, id: \.0.id) { circle, count in
                LayerMarker(symbol: "bag.fill", tint: .pink, label: "\(count)")
                    .position(layout.point(for: circle))
            }
        }
    }
}
