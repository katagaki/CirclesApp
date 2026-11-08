import AXiS
import SwiftData
import SwiftUI

struct UnifiedRouteButton: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator
    @Environment(UserSelections.self) var selections

    @Query var visits: [CirclesVisitEntry]

    var body: some View {
        @Bindable var navigator = navigator
        Group {
            if navigator.isActive {
                Button("Route.End", systemImage: "xmark") {
                    navigator.end()
                }
            } else {
                Button("Route.Title", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath") {
                    startRoute()
                }
                .disabled(selections.map == nil || selections.date == nil)
            }
        }
        .alert("Route.NoStops.Title", isPresented: $navigator.isNoStopsAlertPresented) {
            Button("Shared.OK", role: .cancel) {}
        } message: {
            Text("Route.NoStops.Message")
        }
    }

    func startRoute() {
        guard let map = selections.map, let date = selections.date,
              let hall = ComiketHall(rawValue: map.filename) else { return }
        let eventNumber = planner.activeEventNumber
        navigator.start(
            Navigator.Context(
                eventNumber: eventNumber,
                mapID: map.id,
                mapName: map.name,
                hall: hall,
                day: date.id,
                layouts: mapper.layouts,
                favoriteWebCatalogIDs: Set(favorites.wcIDMappedItems?.keys.map { $0 } ?? []),
                visitedCircleIDs: visits.filter { $0.eventNumber == eventNumber }.map(\.circleID)
            ),
            database: database
        )
    }
}
