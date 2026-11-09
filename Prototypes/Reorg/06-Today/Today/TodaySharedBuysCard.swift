import SwiftUI

struct TodaySharedBuysCard: View {

    @Environment(Harness.self) var harness

    var body: some View {
        TodayCard(title: "Shared Buys", symbol: Feature.sharedBuys.symbol, tint: .purple, destination: .sharedBuys) {
            if harness.isSharedBuysActive {
                HStack(alignment: .top, spacing: 12.0) {
                    ForEach(MockData.members) { member in
                        TodayMemberProgress(member: member)
                    }
                }
            } else {
                HStack(spacing: 12.0) {
                    MemberStack(size: 28.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text("Shop together").font(.headline)
                        Text("Split the circles with friends").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0.0)
                    Button("Start") { harness.isSharedBuysActive = true }
                        .buttonStyle(.glass)
                }
            }
        }
    }
}
