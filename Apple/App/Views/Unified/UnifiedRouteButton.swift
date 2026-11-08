import AXiS
import RADiUS
import SwiftData
import SwiftUI

struct UnifiedRouteButton: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier
    @Environment(UserSelections.self) var selections

    @Query var visits: [CirclesVisitEntry]

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool

    var body: some View {
        Group {
            if navigator.isActive {
                Button("Route.End", systemImage: "xmark") {
                    navigator.end()
                }
            } else {
                Menu("Route.Title", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath") {
                    Button {
                        choose(.efficient)
                    } label: {
                        Text("Route.Mode.Efficient")
                        Text("Route.Mode.Efficient.Description")
                        Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    }
                    Button {
                        choose(.prioritized)
                    } label: {
                        Text("Route.Mode.Prioritized")
                        Text("Route.Mode.Prioritized.Description")
                        Image(systemName: "list.number")
                    }
                    Divider()
                    Button("Route.Onboarding.Open", systemImage: "questionmark.circle") {
                        navigator.pendingMode = nil
                        presentOnboarding()
                    }
                }
                .disabled(selections.map == nil || selections.date == nil)
            }
        }
        .onChange(of: navigator.onboardingDismissals) {
            guard hasSeenOnboarding, let mode = navigator.pendingMode else {
                navigator.pendingMode = nil
                return
            }
            proceed(with: mode)
        }
        .onChange(of: navigator.priorityDismissals) {
            guard let priority = navigator.chosenPriority else { return }
            navigator.chosenPriority = nil
            startRoute(colorPriority: priority)
        }
    }

    func choose(_ mode: Navigator.Mode) {
        navigator.pendingMode = mode
        if hasSeenOnboarding {
            proceed(with: mode)
        } else {
            presentOnboarding()
        }
    }

    func proceed(with mode: Navigator.Mode) {
        navigator.pendingMode = nil
        switch mode {
        case .efficient:
            startRoute(colorPriority: nil)
        case .prioritized:
            navigator.priorityCounts = colorCounts()
            unifier.openRouteScreen(.routePriority)
        }
    }

    func presentOnboarding() {
        unifier.openRouteScreen(.routeOnboarding)
    }

    /// How many favourites of each colour sit on the open map, so the colour list only
    /// offers colours the route could actually visit.
    func colorCounts() -> [WebCatalogColor: Int] {
        let colors = favoriteColors()
        var counts: [WebCatalogColor: Int] = [:]
        for webCatalogIDs in mapper.layouts.values {
            for webCatalogID in webCatalogIDs {
                if let color = colors[webCatalogID] {
                    counts[color, default: 0] += 1
                }
            }
        }
        return counts
    }

    func favoriteColors() -> [Int: WebCatalogColor] {
        (favorites.wcIDMappedItems ?? [:]).mapValues(\.favorite.color)
    }

    func startRoute(colorPriority: [WebCatalogColor]?) {
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
                favoriteColors: favoriteColors(),
                visitedCircleIDs: visits.filter { $0.eventNumber == eventNumber }.map(\.circleID),
                colorPriority: colorPriority
            ),
            database: database
        )
    }
}
