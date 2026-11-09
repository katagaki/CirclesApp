import AXiS
import RADiUS
import SwiftData
import SwiftUI

struct NaviView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator
    @Environment(Unifier.self) var unifier
    @Environment(UserSelections.self) var selections

    @Namespace var namespace

    @Query var visits: [CirclesVisitEntry]

    @State var searchTerm: String = ""
    @State var isSearchActive: Bool = false
    @State var results: [ComiketCircle]?

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool
    @AppStorage(wrappedValue: .regular, "Circles.ListSize") var listDisplayMode: ListDisplayMode

    var isMapReady: Bool {
        selections.map != nil && selections.date != nil
    }

    var body: some View {
        Group {
            if let results {
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchTerm)
                } else {
                    CircleList(
                        circles: results,
                        displayMode: listDisplayMode,
                        namespace: namespace,
                        onSelect: startDirections(to:)
                    )
                }
            } else if navigator.isActive {
                NaviActiveRoute()
            } else {
                List {
                    if navigator.isNoStopsAlertPresented {
                        Section {
                            UnifiedRouteNoStopsCard {
                                navigator.dismissNoStops()
                            }
                        }
                    }
                    NaviFavoritesSection(
                        isEnabled: isMapReady,
                        onChoose: choose(_:),
                        onHelp: {
                            navigator.pendingMode = nil
                            unifier.openRouteScreen(.routeOnboarding)
                        }
                    )
                }
            }
        }
        .navigationTitle("ViewTitle.Navi")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchTerm,
            isPresented: $isSearchActive,
            placement: unifier.displayMode == .panel && unifier.isPanelSideDocked
                ? .navigationBarDrawer(displayMode: .always)
                : .toolbar,
            prompt: "Navi.Search.Prompt"
        )
        .toolbar {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            if navigator.isActive {
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    NaviEndButton()
                }
            }
            SidebarPositionToolbarItem()
        }
        .task(id: searchTerm) {
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
            await search()
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
            startRoute(favoriteColors: favoriteColors(), colorPriority: priority, includesVisited: false)
        }
    }

    func search() async {
        let term = searchTerm.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty, let identifiers = await CatalogCache.searchCircles(term, database: database) else {
            results = nil
            return
        }
        let onMap = Set(mapper.layouts.values.flatMap { $0 })
        results = database.circles(identifiers).filter { circle in
            guard let webCatalogID = circle.extendedInformation?.webCatalogID else { return false }
            return onMap.contains(webCatalogID)
        }
    }

    func choose(_ mode: Navigator.Mode) {
        navigator.pendingMode = mode
        if hasSeenOnboarding {
            proceed(with: mode)
        } else {
            unifier.openRouteScreen(.routeOnboarding)
        }
    }

    func proceed(with mode: Navigator.Mode) {
        navigator.pendingMode = nil
        switch mode {
        case .efficient:
            startRoute(favoriteColors: favoriteColors(), colorPriority: nil, includesVisited: false)
        case .prioritized:
            navigator.priorityCounts = colorCounts()
            unifier.openRouteScreen(.routePriority)
        }
    }

    func startDirections(to circle: ComiketCircle) {
        guard let webCatalogID = circle.extendedInformation?.webCatalogID else { return }
        searchTerm = ""
        isSearchActive = false
        let color = favoriteColors()[webCatalogID] ?? .uncolored
        startRoute(favoriteColors: [webCatalogID: color], colorPriority: nil, includesVisited: true)
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

    func startRoute(favoriteColors: [Int: WebCatalogColor], colorPriority: [WebCatalogColor]?, includesVisited: Bool) {
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
                favoriteColors: favoriteColors,
                visitedCircleIDs: includesVisited
                    ? []
                    : visits.filter { $0.eventNumber == eventNumber }.map(\.circleID),
                colorPriority: colorPriority
            ),
            database: database
        )
    }
}
