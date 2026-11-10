import SwiftUI

struct WalletCardDetail: View {

    @Environment(Harness.self) var harness
    let card: WalletCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            switch card {
            case .catalog:
                Text("Search circles in \(harness.hall.name) and beyond")
                HStack(spacing: 6.0) {
                    ForEach(harness.circlesForSelection.prefix(7)) { circle in
                        CircleCut(circle: circle, size: 26.0)
                    }
                }
            case .favorites:
                Text("\(harness.routeStops.count) in \(harness.hall.name) today")
                HStack(spacing: 10.0) {
                    ForEach(FavoriteColor.allCases.filter { color in harness.favorites.values.contains(color) }) { color in
                        HStack(spacing: 4.0) {
                            Rectangle().fill(color.color).frame(width: 12.0, height: 12.0)
                                .overlay(Rectangle().stroke(.white, lineWidth: 1.0))
                            Text("\(harness.favorites.values.filter { $0 == color }.count)")
                        }
                    }
                }
            case .buys:
                Text("\(harness.buysRemaining) left to buy · \(harness.buys.count - harness.buysRemaining) bought")
                ProgressView(value: Double(harness.buys.count - harness.buysRemaining), total: Double(max(harness.buys.count, 1)))
                    .tint(.white)
            case .sharedBuys:
                Text(harness.isSharedBuysActive ? "Shopping with Aoi and Mika" : "Share your list and split up the circles")
                Text(harness.isSharedBuysActive ? "3 items assigned to others" : "Tap to start or join a list")
                    .opacity(0.8)
            case .navigation:
                if harness.isNavigating, let stop = harness.nextStop {
                    Text("\(stop.name) · stop \(harness.routeStep + 1) of \(harness.routeStops.count)")
                } else {
                    Text("Walk through your favorites in \(harness.hall.name)")
                }
                Text(harness.isNavigating ? "Tap for all stops" : "Shortest walk or by priority").opacity(0.8)
            case .myComiket:
                HStack(spacing: 10.0) {
                    ProfileAvatar(size: 34.0)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    Text(harness.isGuest ? "Sign in to plan your days" : "Going Day 1 · Sat 27 Dec")
                }
            case .settings:
                Text("Event data, backup, map and circle display, links, account")
                Text(harness.isOffline ? "Offline · using downloaded data" : "C107 · 1.6 GB downloaded").opacity(0.8)
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
