import SwiftUI

struct GoHome: View {

    @Environment(Harness.self) var harness

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10.0) {
                if harness.isNavigating {
                    NextStopCard()
                } else {
                    GoStartRouteCard()
                }
                GoSharedStrip()
                GuestBanner()
                GoSectionTitle(title: "Still to Buy", detail: "\(harness.buysRemaining) · ¥\(remainingTotal.formatted())")
                GoCard {
                    ForEach(harness.buys.filter { !$0.isBought }) { item in
                        BuyRow(item: item)
                    }
                }
                GoSectionTitle(title: "Offline Readiness")
                GoReadinessCard()
                GoSectionTitle(title: "More")
                GoCard {
                    GoLinkRow(feature: .navigation, title: "All Route Stops")
                    GoLinkRow(feature: .buys, title: "Full Buys List")
                    GoLinkRow(feature: .settings, title: "Settings")
                }
            }
            .padding(16.0)
        }
    }

    var remainingTotal: Int {
        harness.buys.filter { !$0.isBought }.reduce(0) { $0 + $1.price }
    }
}
