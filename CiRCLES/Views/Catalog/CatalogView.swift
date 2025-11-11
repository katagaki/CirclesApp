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

    @Environment(\.modelContext) var modelContext

    // Search
    @State var isSearchActive: Bool = false
    @State var searchTerm: String = ""

    // Display
    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular

    @AppStorage(wrappedValue: false, "Database.Initialized") var isDatabaseInitialized: Bool

    @Namespace var namespace

    var body: some View {
        ZStack(alignment: .center) {
            if catalogCache.isLoading {
                ProgressView("Circles.Loading")
                Color.clear
            } else {
                switch displayModeState {
                case .grid:
                    if let searchedCircles = catalogCache.searchedCircles {
                        CircleGrid(circles: searchedCircles, namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleGrid(circles: catalogCache.displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    }
                case .list:
                    if let searchedCircles = catalogCache.searchedCircles {
                        CircleList(circles: searchedCircles,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleList(circles: catalogCache.displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            unifier.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    }
                }
                if selections.genre == nil && selections.map == nil && catalogCache.searchedCircles == nil {
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
            @Bindable var catalogCache = catalogCache
            ToolbarItem(placement: .topBarLeading) {
                DisplayModeSwitcher($displayModeState)
            }
            if displayModeState == .list {
                ToolbarItem(placement: .topBarLeading) {
                    ListModeSwitcher($listDisplayModeState)
                }
            }
            CatalogToolbar(displayedCircles: $catalogCache.displayedCircles)
        }
        .searchable(
            text: $searchTerm,
            isPresented: $isSearchActive,
            placement: .toolbar,
            prompt: "Circles.Search.Prompt"
        )
        .onAppear {
            if !catalogCache.isInitialLoadCompleted {
                Task { await reloadDisplayedCircles() }
            }
        }
        .onChange(of: selections.catalogSelectionId) {
            Task { await reloadDisplayedCircles() }
        }
        .onChange(of: searchTerm) {
            Task { await searchCircles() }
        }
        .onChange(of: isSearchActive) {
            if isSearchActive && unifier.isMinimized {
                unifier.selectedDetent = .height(360)
            }
        }
        .onChange(of: isDatabaseInitialized) { _, newValue in
            if !newValue {
                catalogCache.displayedCircles.removeAll()
            }
        }
    }

    func reloadDisplayedCircles() async {
        withAnimation(.smooth.speed(2.0)) {
            catalogCache.isLoading = true
        } completion: {
            catalogCache.isInitialLoadCompleted = true
            let selectedGenreId = selections.genre?.id
            let selectedMapId = selections.map?.id
            let selectedBlockId = selections.block?.id
            Task.detached {
                let circleIdentifiers = await CatalogCache.displayedCircles(
                    genreID: selectedGenreId,
                    mapID: selectedMapId,
                    blockID: selectedBlockId
                )
                await MainActor.run {
                    var displayedCircles: [ComiketCircle] = []
                    displayedCircles = database.circles(circleIdentifiers)
                    if let selectedDate = selections.date {
                        displayedCircles.removeAll(where: { $0.day != selectedDate.id })
                    }
                    withAnimation(.smooth.speed(2.0)) {
                        catalogCache.displayedCircles = displayedCircles
                        catalogCache.isLoading = false
                    }
                }
            }
        }
    }

    func searchCircles() async {
        Task.detached {
            let circleIdentifiers = await CatalogCache.searchCircles(searchTerm)
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
