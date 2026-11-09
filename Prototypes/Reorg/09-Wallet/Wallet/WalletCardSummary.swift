import SwiftUI

struct WalletCardSummary: View {

    @Environment(Harness.self) var harness
    let card: WalletCard

    var body: some View {
        Group {
            switch card {
            case .catalog:
                Text("\(harness.circlesForSelection.count) on Day \(harness.day)")
            case .favorites:
                Text("\(harness.favorites.count) circles")
            case .buys:
                Text("¥\(harness.buysTotal.formatted())")
            case .sharedBuys:
                if harness.isSharedBuysActive {
                    MemberStack(size: 22.0)
                } else {
                    Text("Not shared")
                }
            case .navigation:
                if harness.isNavigating, let stop = harness.nextStop {
                    Text("Next \(stop.spaceName)")
                } else {
                    Text("\(harness.routeStops.count) stops")
                }
            case .myComiket:
                Text(harness.isGuest ? "Guest" : "Justin")
            case .settings:
                if harness.isOffline {
                    Label("Offline", systemImage: "wifi.slash")
                } else {
                    Text("C107 ready")
                }
            }
        }
        .font(.subheadline.weight(.semibold).monospacedDigit())
        .lineLimit(1)
        .opacity(0.92)
    }
}
