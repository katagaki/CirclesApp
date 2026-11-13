import AXiS
import ORBiT
import RADiUS
import SwiftData
import SwiftUI

struct NaviView: View {

    @Environment(Database.self) var database
    @Environment(Events.self) var planner
    @Environment(Favorites.self) var favorites
    @Environment(Mapper.self) var mapper
    @Environment(Navigator.self) var navigator
    @Environment(SharedBuysSession.self) var sharedBuys
    @Environment(Unifier.self) var unifier
    @Environment(UserSelections.self) var selections

    @Namespace var namespace

    @Query var visits: [CirclesVisitEntry]

    @State var searchTerm: String = ""
    @State var isSearchActive: Bool = false
    @State var results: [ComiketCircle]?
    @State var pendingDestination: ComiketCircle?
    @State var isOnboardingPresented: Bool = false
    @State var pendingGo: (() -> Void)?
    @State var isSafetyAlertPresented: Bool = false

    @AppStorage(wrappedValue: false, "Route.HasSeenOnboarding") var hasSeenOnboarding: Bool
    @AppStorage(wrappedValue: false, "Route.HidesSafetyAlert") var hidesSafetyAlert: Bool
    @AppStorage(wrappedValue: .grid, "Circles.DisplayMode") var displayMode: CircleDisplayMode
    @AppStorage(wrappedValue: .regular, "Circles.ListSize") var listDisplayMode: ListDisplayMode
    @AppStorage(wrappedValue: .medium, "Circles.GridSize") var gridDisplayMode: GridDisplayMode

    var isMapReady: Bool {
        selections.map != nil && selections.date != nil
    }

    var body: some View {
        Group {
            if let results {
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchTerm)
                } else {
                    switch displayMode {
                    case .grid:
                        CircleGrid(
                            displayMode: gridDisplayMode,
                            circles: results,
                            namespace: namespace,
                            onSelect: startDirections(to:)
                        )
                    case .list:
                        CircleList(
                            circles: results,
                            displayMode: listDisplayMode,
                            namespace: namespace,
                            onSelect: startDirections(to:)
                        )
                    }
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
                    NaviModesSection(
                        isEnabled: isMapReady,
                        ownBuysCount: ownBuysOnMap.count,
                        sharedBuysCount: sharedBuys.isActive ? sharedBuysOnMap.count : nil,
                        onChoose: { mode in go { choose(mode) } },
                        onOwnBuys: { go { routeThrough(ownBuysOnMap) } },
                        onSharedBuys: { go { routeThrough(sharedBuysOnMap) } }
                    )
                }
                .listSectionSpacing(.compact)
            }
        }
        .navigationTitle("ViewTitle.Navi")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(NaviSearchModifier(text: $searchTerm, isPresented: $isSearchActive))
        .toolbar {
            if navigator.isActive {
                ToolbarItem(placement: .bottomBar) {
                    NaviEndButton()
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                NaviStepToolbar()
            } else {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                ToolbarSpacer(.fixed, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    Button("Route.Onboarding.Open", systemImage: "questionmark") {
                        navigator.pendingMode = nil
                        isOnboardingPresented = true
                    }
                }
            }
            SidebarPositionToolbarItem()
        }
        .onChange(of: navigator.isActive) {
            guard navigator.isActive else { return }
            searchTerm = ""
            isSearchActive = false
            results = nil
        }
        .task(id: searchTerm) {
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
            await search()
        }
        .onChange(of: mapper.layouts) {
            guard let destination = pendingDestination,
                  let webCatalogID = destination.extendedInformation?.webCatalogID,
                  mapper.layouts.values.contains(where: { $0.contains(webCatalogID) }) else { return }
            pendingDestination = nil
            routeDirectly(to: webCatalogID)
        }
        .alert(
            "Route.SafetyAlert.Title",
            isPresented: $isSafetyAlertPresented
        ) {
            Button("Route.SafetyAlert.GotIt", role: .cancel) {
                continueGo()
            }
            Button("Route.SafetyAlert.DontShowAgain") {
                hidesSafetyAlert = true
                continueGo()
            }
        }
        .sheet(isPresented: $isOnboardingPresented) {
            guard hasSeenOnboarding, let mode = navigator.pendingMode else {
                navigator.pendingMode = nil
                return
            }
            proceed(with: mode)
        } content: {
            RouteOnboardingView()
        }
        .onChange(of: navigator.priorityDismissals) {
            guard let priority = navigator.chosenPriority else { return }
            navigator.chosenPriority = nil
            startRoute(favoriteColors: favoriteColors(), colorPriority: priority, includesVisited: false)
        }
    }

    func search() async {
        if let identifiers = await CatalogCache.searchCircles(searchTerm, database: database) {
            results = database.circles(identifiers)
        } else {
            results = nil
        }
    }

    /// Circles on the open map with something of yours still to buy.
    var ownBuysOnMap: [Int] {
        let circleIDs = BuysDatabase.shared.entries(for: planner.activeEventNumber)
            .filter { entry in
                entry.items.contains { $0.status == .pending && !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            }
            .map(\.circleID)
        return webCatalogIDsOnMap(for: circleIDs)
    }

    /// Circles on the open map with a shared item still to buy that is yours or nobody's.
    var sharedBuysOnMap: [Int] {
        let circleIDs = sharedBuys.items
            .filter { $0.status == .pending && ($0.assignee == nil || $0.assignee == sharedBuys.actorPID) }
            .map(\.circleID)
        return webCatalogIDsOnMap(for: Array(Set(circleIDs)))
    }

    func webCatalogIDsOnMap(for circleIDs: [Int]) -> [Int] {
        guard !circleIDs.isEmpty else { return [] }
        let onMap = Set(mapper.layouts.values.flatMap { $0 })
        return database.circles(circleIDs)
            .compactMap { $0.extendedInformation?.webCatalogID }
            .filter { onMap.contains($0) }
    }

    func routeThrough(_ webCatalogIDs: [Int]) {
        guard !webCatalogIDs.isEmpty else { return }
        let colors = favoriteColors()
        let stops = Dictionary(
            webCatalogIDs.map { ($0, colors[$0] ?? .uncolored) },
            uniquingKeysWith: { first, _ in first }
        )
        startRoute(
            favoriteColors: stops,
            colorPriority: nil,
            includesVisited: true
        )
    }

    func go(_ action: @escaping () -> Void) {
        if hidesSafetyAlert {
            action()
        } else {
            pendingGo = action
            isSafetyAlertPresented = true
        }
    }

    func continueGo() {
        let action = pendingGo
        pendingGo = nil
        action?()
    }

    func choose(_ mode: Navigator.Mode) {
        navigator.pendingMode = mode
        if hasSeenOnboarding {
            proceed(with: mode)
        } else {
            isOnboardingPresented = true
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
        if mapper.layouts.values.contains(where: { $0.contains(webCatalogID) }) {
            routeDirectly(to: webCatalogID)
        } else {
            pendingDestination = circle
            Task {
                await openMap(for: circle)
            }
        }
    }

    func routeDirectly(to webCatalogID: Int) {
        let color = favoriteColors()[webCatalogID] ?? .uncolored
        startRoute(favoriteColors: [webCatalogID: color], colorPriority: nil, includesVisited: true)
    }

    /// The circle is on another hall or day: opens that map first, and the route starts once
    /// its layouts have loaded.
    func openMap(for circle: ComiketCircle) async {
        let actor = DataFetcher(database: database.getTextDatabase())
        guard let mapID = await actor.mapID(forBlock: circle.blockID),
              let map = database.maps().first(where: { $0.id == mapID }),
              let date = database.dates().first(where: { $0.id == circle.day }) else {
            pendingDestination = nil
            return
        }
        selections.map = map
        selections.date = date
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
