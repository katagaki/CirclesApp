import SwiftUI

struct TodayBuysCard: View {

    @Environment(Harness.self) var harness
    let budget = 10_000

    var spent: Int {
        harness.buys.filter(\.isBought).reduce(0) { $0 + $1.price }
    }

    var body: some View {
        TodayCard(title: "Buys", symbol: "bag.fill", tint: .pink, destination: .buys) {
            VStack(alignment: .leading, spacing: 8.0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("¥\((budget - spent).formatted()) left")
                        .font(.title3.weight(.bold).monospacedDigit())
                    Text("of ¥\(budget.formatted()) budget").font(.caption).foregroundStyle(.secondary)
                }
                ProgressView(value: Double(spent), total: Double(budget)).tint(.pink)
                Text("\(harness.buysRemaining) items still to buy · ¥\((harness.buysTotal - spent).formatted()) planned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
