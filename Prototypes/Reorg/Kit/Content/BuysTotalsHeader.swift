import SwiftUI

struct BuysTotalsHeader: View {

    @Environment(Harness.self) var harness

    var body: some View {
        HStack(spacing: 10.0) {
            StatTile(title: "Total", value: "¥\(harness.buysTotal.formatted())", tint: .pink)
            StatTile(title: "Left to buy", value: "\(harness.buysRemaining)", tint: .orange)
            StatTile(title: "Circles", value: "\(Set(harness.buys.map(\.circleID)).count)", tint: .indigo)
        }
    }
}
