import SwiftUI

struct SpotlightSuggestions: View {

    @Environment(Harness.self) var harness

    static let recentIDs = [1006, 1003, 1012, 1021, 1009, 1015]

    var body: some View {
        Section("Recent Circles") {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12.0) {
                    ForEach(SpotlightSuggestions.recentIDs.compactMap(MockData.circle)) { circle in
                        NavigationLink(value: circle) {
                            SpotlightRecentCircle(circle: circle)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16.0)
            }
            .scrollIndicators(.hidden)
            .listRowInsets(EdgeInsets(top: 12.0, leading: 0.0, bottom: 12.0, trailing: 0.0))
        }
        Section("Jump To") {
            if harness.isNavigating, let stop = harness.nextStop {
                NavigationLink(value: stop) {
                    SpotlightRowLabel(title: "Next stop \(stop.spaceName)", subtitle: stop.name,
                                      symbol: "location.north.fill", tint: .blue)
                }
            } else {
                NavigationLink(value: Feature.navigation) {
                    SpotlightRowLabel(title: "Plan a route", subtitle: "\(harness.routeStops.count) favorites in \(harness.hall.name)",
                                      symbol: Feature.navigation.symbol, tint: .blue)
                }
            }
            NavigationLink(value: Feature.sharedBuys) {
                SpotlightRowLabel(title: "Shared Buys",
                                  subtitle: harness.isSharedBuysActive ? "Shared with Aoi and Mika" : "Shop together with friends",
                                  symbol: Feature.sharedBuys.symbol, tint: .purple)
            }
            NavigationLink(value: Feature.buys) {
                SpotlightRowLabel(title: "Buys", subtitle: "¥\(harness.buysTotal.formatted()) · \(harness.buysRemaining) left",
                                  symbol: Feature.buys.symbol, tint: .pink)
            }
            NavigationLink(value: Feature.eventData) {
                SpotlightRowLabel(title: "Event Data",
                                  subtitle: harness.isOffline ? "Offline · using downloaded data" : "C107 · up to date",
                                  symbol: Feature.eventData.symbol, tint: .gray)
            }
        }
    }
}
