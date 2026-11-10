import SwiftUI

struct LauncherTiles: View {

    @Environment(Harness.self) var harness

    var todayFavorites: Int {
        harness.favoriteCircles.filter { $0.day == harness.day }.count
    }

    var routeSubtitle: String {
        if harness.isNavigating, let stop = harness.nextStop {
            return "Next stop \(stop.spaceName)"
        }
        return "\(harness.routeStops.count) stops in \(harness.hall.name)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18.0) {
            LauncherSection(title: "Plan") {
                LauncherTile(feature: .catalog,
                             subtitle: "\(harness.circlesForSelection.count) circles on Day \(harness.day)")
                LauncherTile(feature: .favorites,
                             subtitle: "\(harness.favorites.count) favorites · \(todayFavorites) today")
                LauncherTile(feature: .buys,
                             subtitle: "¥\(harness.buysTotal.formatted()) · \(harness.buysRemaining) left")
                LauncherTile(feature: .myComiket,
                             subtitle: harness.isGuest ? "Sign in to plan days" : "Going Day 1")
            }
            LauncherSection(title: "At the Event") {
                LauncherTile(feature: .navigation, subtitle: routeSubtitle, isLive: harness.isNavigating)
                LauncherTile(feature: .sharedBuys,
                             subtitle: harness.isSharedBuysActive ? "Shared with Aoi and Mika" : "Shop with friends",
                             isLive: harness.isSharedBuysActive)
            }
            LauncherSection(title: "Account & Data") {
                LauncherTile(feature: .eventData,
                             subtitle: harness.isOffline ? "Offline · using downloads" : "C107 · up to date")
                LauncherTile(feature: .settings, subtitle: "Map, circles, privacy")
            }
        }
    }
}
