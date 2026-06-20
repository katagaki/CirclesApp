//
//  CatalogView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SwiftData
import SwiftUI
import AXiS

struct CatalogView: View {

    @Environment(Authenticator.self) var authenticator
    @Environment(CatalogCache.self) var catalogCache
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier
    @Environment(Events.self) var planner

    // Search
    @State var isSearchActive: Bool = false
    @State var searchTerm: String = ""

    // Display
    @AppStorage(wrappedValue: .grid, "Circles.DisplayMode") var displayMode: CircleDisplayMode
    @AppStorage(wrappedValue: .regular, "Circles.ListSize") var listDisplayMode: ListDisplayMode
    @AppStorage(wrappedValue: .medium, "Circles.GridSize") var gridDisplayMode: GridDisplayMode

    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular
    @State var gridDisplayModeState: GridDisplayMode = .medium

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool
    @AppStorage(wrappedValue: true, "Customization.DoubleTapToVisit") var isDoubleTapToVisitEnabled: Bool

    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .center) {
            let doubleTapAction = isDoubleTapToVisitEnabled ? toggleVisitState : nil
            if catalogCache.isLoading {
                ProgressView("Circles.Loading")
                Color.clear
            } else {
                switch displayModeState {
                case .grid:
                    if let searchedCircles = catalogCache.searchedCircles {
                        CircleGrid(
                            displayMode: gridDisplayModeState,
                            circles: searchedCircles,
                            namespace: namespace,
                            onSelect: { circle in
                                unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                            },
                            onDoubleTap: doubleTapAction
                        )
                    } else {
                        CircleGrid(
                            displayMode: gridDisplayModeState,
                            circles: catalogCache.displayedCircles,
                            showsOverlayWhenEmpty: !selections.genres.isEmpty || selections.map != nil,
                            namespace: namespace,
                            onSelect: { circle in
                                unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                            },
                            onDoubleTap: doubleTapAction
                        )
                    }
                case .list:
                    if let searchedCircles = catalogCache.searchedCircles {
                        CircleList(
                            circles: searchedCircles,
                            displayMode: listDisplayModeState,
                            namespace: namespace,
                            onSelect: { circle in
                                unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                            },
                            onDoubleTap: doubleTapAction
                        )
                    } else {
                        CircleList(
                            circles: catalogCache.displayedCircles,
                            showsOverlayWhenEmpty: !selections.genres.isEmpty || selections.map != nil,
                            displayMode: listDisplayModeState,
                            namespace: namespace,
                            onSelect: { circle in
                                unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                            },
                            onDoubleTap: doubleTapAction
                        )
                    }
                }
                if selections.genres.isEmpty && selections.map == nil && catalogCache.searchedCircles == nil {
                    ContentUnavailableView(
                        "Circles.NoFilterSelected",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Circles.NoFilterSelected.Description")
                    )
                }
            }
        }
        .navigationTitle("ViewTitle.Circles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ToolbarItem(placement: .topBarLeading) {
                    displaySettingsMenu()
                }
            }
            CatalogToolbar()
            if UIDevice.current.userInterfaceIdiom != .phone {
                ToolbarSpacer(.flexible, placement: .bottomBar)
                ToolbarItem(placement: .bottomBar) {
                    displaySettingsMenu()
                }
                SidebarPositionToolbarItem()
            }
        }
        .searchable(
            text: $searchTerm,
            isPresented: $isSearchActive,
            placement: .toolbar,
            prompt: "Circles.Search.Prompt"
        )
        .onAppear {
            if catalogCache.invalidationID != selections.catalogSelectionID {
                reloadDisplayedCircles()
            }
            displayModeState = displayMode
            listDisplayModeState = listDisplayMode
            gridDisplayModeState = gridDisplayMode
        }
        .onChange(of: displayModeState) {
            displayMode = displayModeState
        }
        .onChange(of: listDisplayModeState) {
            listDisplayMode = listDisplayModeState
        }
        .onChange(of: gridDisplayModeState) {
            gridDisplayMode = gridDisplayModeState
        }
        .onChange(of: selections.catalogSelectionID) {
            reloadDisplayedCircles()
        }
        .onChange(of: searchTerm) {
            searchCircles()
        }
        .onChange(of: isSearchActive) {
            if isSearchActive && unifier.isMinimized {
                unifier.selectedDetent = .height(360)
            }
        }
        .onChange(of: isDatabaseInitialized) {
            if !isDatabaseInitialized {
                catalogCache.displayedCircles.removeAll()
            }
        }
    }

    @ViewBuilder
    func displaySettingsMenu() -> some View {
        DisplaySettingsMenu(
            displayMode: $displayModeState,
            listDisplayMode: $listDisplayModeState,
            gridDisplayMode: $gridDisplayModeState
        )
    }

    func reloadDisplayedCircles() {
        let animated = unifier.animatesReload
        unifier.animatesReload = true

        let loadCircles = {
            catalogCache.invalidationID = selections.catalogSelectionID
            let selectedGenreIDs = selections.genres.isEmpty ? nil :
                Array(selections.genres.map({ (genre: ComiketGenre) in genre.id }))
            let selectedMapID = selections.map?.id
            let selectedBlockIDs = selections.blocks.isEmpty ? nil :
                Array(selections.blocks.map({ (block: ComiketBlock) in block.id }))
            let selectedDayID = selections.date?.id
            Task.detached(priority: .high) {
                let circleIdentifiers = await CatalogCache.fetchCircles(
                    genreIDs: selectedGenreIDs,
                    mapID: selectedMapID,
                    blockIDs: selectedBlockIDs,
                    dayID: selectedDayID,
                    database: database
                )

                await MainActor.run {
                    let displayedCircles = database.circles(circleIdentifiers)
                    if animated {
                        withAnimation(.smooth.speed(2.0)) {
                            catalogCache.displayedCircles = displayedCircles
                            catalogCache.isLoading = false
                        }
                    } else {
                        catalogCache.displayedCircles = displayedCircles
                        catalogCache.isLoading = false
                    }
                }
            }
        }

        if animated {
            withAnimation(.smooth.speed(2.0)) {
                catalogCache.isLoading = true
            } completion: {
                loadCircles()
            }
        } else {
            catalogCache.isLoading = true
            loadCircles()
        }
    }

    func toggleVisitState(circle: ComiketCircle) {
        let circleID = circle.id
        let eventNumber = planner.activeEventNumber
        Task.detached {
            let actor = VisitActor(modelContainer: sharedModelContainer)
            await actor.toggleVisit(circleID: circleID, eventNumber: eventNumber)
        }
    }

    func searchCircles() {
        Task.detached {
            let circleIdentifiers = await CatalogCache.searchCircles(searchTerm, database: database)

            if let circleIdentifiers {
                await MainActor.run {
                    let searchedCircles = database.circles(circleIdentifiers)
                    withAnimation(.smooth.speed(2.0)) {
                        catalogCache.searchedCircles = searchedCircles
                    }
                }
            } else {
                await MainActor.run {
                    withAnimation(.smooth.speed(2.0)) {
                        catalogCache.searchedCircles = nil
                    }
                }
            }
        }

    }
}
