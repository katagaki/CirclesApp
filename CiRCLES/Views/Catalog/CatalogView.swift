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
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database
    @Environment(UserSelections.self) var selections
    @Environment(Unifier.self) var unifier

    @Environment(\.modelContext) var modelContext

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?

    @State var blocksInMap: [ComiketBlock] = []

    // Search
    @State var isSearchActive: Bool = false
    @State var searchTerm: String = ""

    @State var isInitialLoadCompleted: Bool = false
    @State var isLoading: Bool = false

    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .center) {
            if isLoading {
                ProgressView("Circles.Loading")
                Color.clear
            } else {
                switch displayModeState {
                case .grid:
                    if let searchedCircles {
                        CircleGrid(circles: searchedCircles, namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleGrid(circles: displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    }
                case .list:
                    if let searchedCircles {
                        CircleList(circles: searchedCircles,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleList(circles: displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    }
                }
                if selections.genre == nil && selections.map == nil && searchedCircles == nil {
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
                DisplayModeSwitcher($displayModeState)
            }
            if displayModeState == .list {
                ToolbarItem(placement: .topBarLeading) {
                    ListModeSwitcher($listDisplayModeState)
                }
            }
            CatalogToolbar(displayedCircles: $displayedCircles)
        }
        .searchable(
            text: $searchTerm,
            isPresented: $isSearchActive,
            placement: .toolbar,
            prompt: "Circles.Search.Prompt"
)
        .onAppear {
            if !isInitialLoadCompleted {
                reloadDisplayedCircles(
                    genreID: selections.genre?.id,
                    mapID: selections.map?.id,
                    blockID: selections.block?.id
                )
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selections.catalogSelectionId) {
            if isInitialLoadCompleted {
                reloadDisplayedCircles(
                    genreID: selections.genre?.id,
                    mapID: selections.map?.id,
                    blockID: selections.block?.id
                )
            }
        }
        .onChange(of: isSearchActive) {
            if isSearchActive && unifier.isMinimized {
                unifier.selectedDetent = .height(360)
            }
        }
        .onChange(of: searchTerm) {
            Task.detached {
                await searchCircles()
            }
        }
        .onChange(of: isDatabaseInitialized) { _, newValue in
            if !newValue {
                displayedCircles.removeAll()
            }
        }
    }

    func reloadDisplayedCircles(genreID: Int?, mapID: Int?, blockID: Int?) {
        withAnimation(.smooth.speed(2.0)) {
            self.isLoading = true
        } completion: {
            Task.detached {
                let actor = DataFetcher(modelContainer: sharedModelContainer)

                var circleIdentifiersByGenre: [PersistentIdentifier]?
                var circleIdentifiersByMap: [PersistentIdentifier]?
                var circleIdentifiersByBlock: [PersistentIdentifier]?
                var circleIdentifiers: [PersistentIdentifier] = []

                if let genreID {
                    circleIdentifiersByGenre = await actor.circles(withGenre: genreID)
                }
                if let mapID {
                    circleIdentifiersByMap = await actor.circles(inMap: mapID)
                }
                if let blockID {
                    circleIdentifiersByBlock = await actor.circles(inBlock: blockID)
                }

                if let circleIdentifiersByGenre {
                    circleIdentifiers = circleIdentifiersByGenre
                }
                if let circleIdentifiersByMap {
                    if circleIdentifiers.isEmpty {
                        circleIdentifiers = circleIdentifiersByMap
                    } else {
                        circleIdentifiers = Array(
                            Set(circleIdentifiers).intersection(Set(circleIdentifiersByMap))
                        )
                    }
                }
                if let circleIdentifiersByBlock {
                    circleIdentifiers = Array(
                        Set(circleIdentifiers).intersection(Set(circleIdentifiersByBlock))
                    )
                }

                await MainActor.run {
                    var displayedCircles: [ComiketCircle] = []
                    displayedCircles = database.circles(circleIdentifiers)
                    if let selectedDate = selections.date {
                        displayedCircles.removeAll(where: { $0.day != selectedDate.id })
                    }
                    withAnimation(.smooth.speed(2.0)) {
                        self.displayedCircles = displayedCircles
                        self.isLoading = false
                    }
                }
            }
        }
    }

    func searchCircles() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)
            await MainActor.run {
                let searchedCircles = database.circles(circleIdentifiers)
                withAnimation(.smooth.speed(2.0)) {
                    self.searchedCircles = searchedCircles
                }
            }
        } else {
            await MainActor.run {
                withAnimation(.smooth.speed(2.0)) {
                    searchedCircles = nil
                }
            }
        }
    }
}
