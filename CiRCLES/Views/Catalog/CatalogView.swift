//
//  CatalogView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftData
import SwiftUI

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

    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular

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
                            circles: searchedCircles,
                            namespace: namespace,
                            onSelect: { circle in
                                unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                            },
                            onDoubleTap: doubleTapAction
                        )
                    } else {
                        CircleGrid(
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
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    DisplayModeSwitcher(mode: $displayModeState)
                    if displayModeState == .list {
                        ListModeSwitcher(mode: $listDisplayModeState)
                    }
                }
            }
            CatalogToolbar()
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
        }
        .onChange(of: displayModeState) {
            displayMode = displayModeState
        }
        .onChange(of: listDisplayModeState) {
            listDisplayMode = listDisplayModeState
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

    func reloadDisplayedCircles() {
        withAnimation(.smooth.speed(2.0)) {
            catalogCache.isLoading = true
        } completion: {
            catalogCache.invalidationID = selections.catalogSelectionID
            let selectedGenreIDs = selections.genres.isEmpty ? nil :
                Array(selections.genres.map({ (genre: ComiketGenre) in genre.id }))
            let selectedMapID = selections.map?.id
            let selectedBlockIDs = selections.blocks.isEmpty ? nil :
                Array(selections.blocks.map({ (block: ComiketBlock) in block.id }))
            let selectedDayID = selections.date?.id
            Task.detached {
                await database.connect()
                let textDatabase = await database.textDatabase
                let circleIdentifiers = await CatalogCache.fetchCircles(
                    genreIDs: selectedGenreIDs,
                    mapID: selectedMapID,
                    blockIDs: selectedBlockIDs,
                    dayID: selectedDayID,
                    database: textDatabase
                )

                await MainActor.run {
                    var displayedCircles: [ComiketCircle] = []
                    displayedCircles = database.circles(circleIdentifiers)
                    withAnimation(.smooth.speed(2.0)) {
                        catalogCache.displayedCircles = displayedCircles
                        catalogCache.isLoading = false
                    }
                }
            }
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
            await database.connect()
            let textDatabase = await database.textDatabase
            let circleIdentifiers = await CatalogCache.searchCircles(searchTerm, database: textDatabase)

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
