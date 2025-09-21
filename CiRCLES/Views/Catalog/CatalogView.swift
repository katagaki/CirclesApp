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
    @Environment(Sheets.self) var sheets

    @Environment(\.modelContext) var modelContext

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?

    @State var blocksInMap: [ComiketBlock] = []

    @State var searchTerm: String = ""

    @State var isInitialLoadCompleted: Bool = false
    @State var isLoading: Bool = false

    @AppStorage(wrappedValue: CircleDisplayMode.grid, "Circles.DisplayMode") var displayMode: CircleDisplayMode
    @AppStorage(wrappedValue: ListDisplayMode.regular, "Circles.ListSize") var listDisplayMode: ListDisplayMode
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
                            sheets.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleGrid(circles: displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   namespace: namespace) { circle in
                            sheets.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    }
                case .list:
                    if let searchedCircles {
                        CircleList(circles: searchedCircles,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            sheets.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
                        }
                    } else {
                        CircleList(circles: displayedCircles,
                                   showsOverlayWhenEmpty: selections.genre != nil || selections.map != nil,
                                   displayMode: listDisplayModeState,
                                   namespace: namespace) { circle in
                            sheets.append(.namespacedCircleDetail(circle: circle, namespace: namespace))
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
                Button {
                    withAnimation(.smooth.speed(2.0)) {
                        switch displayModeState {
                        case .grid: displayModeState = .list
                        case .list: displayModeState = .grid
                        }
                    }
                } label: {
                    switch displayModeState {
                    case .grid:
                        Label("Shared.DisplayMode.List", systemImage: "rectangle.grid.1x2")
                    case .list:
                        Label("Shared.DisplayMode.Grid", systemImage: "rectangle.grid.3x2")
                    }
                }
            }
            if displayModeState == .list {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.smooth.speed(2.0)) {
                            switch listDisplayModeState {
                            case .regular: listDisplayModeState = .compact
                            case .compact: listDisplayModeState = .regular
                            }
                        }
                    } label: {
                        switch listDisplayMode {
                        case .regular:
                            Label("Shared.DisplayMode.List.Compact", systemImage: "rectangle.compress.vertical")
                        case .compact:
                            Label("Shared.DisplayMode.List.Regular", systemImage: "rectangle.expand.vertical")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            if searchTerm.trimmingCharacters(in: .whitespaces).count < 2 {
                if #available(iOS 26.0, *) {
                    CatalogToolbar(displayedCircles: $displayedCircles)
                        .transition(.opacity.animation(.snappy.speed(2.0)))
                } else {
                    BarAccessory(placement: .bottom) {
                        CatalogToolbar(displayedCircles: $displayedCircles)
                            .transition(.opacity.animation(.snappy.speed(2.0)))
                    }
                }
            }
        }
        .searchable(text: $searchTerm,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Circles.Search.Prompt")
        .onAppear {
            if !isInitialLoadCompleted {
                displayModeState = displayMode
                listDisplayModeState = listDisplayMode
                reloadDisplayedCircles(
                    genreID: selections.genre?.id,
                    mapID: selections.map?.id,
                    blockID: selections.block?.id
                )
                isInitialLoadCompleted = true
            }
        }
        .onChange(of: selections.idMap) { _, _ in
            if isInitialLoadCompleted {
                reloadDisplayedCircles(
                    genreID: selections.genre?.id,
                    mapID: selections.map?.id,
                    blockID: selections.block?.id
                )
            }
        }
        .onChange(of: searchTerm) { _, _ in
            Task.detached {
                await searchCircles()
            }
        }
        .onChange(of: displayModeState) { _, _ in
            displayMode = displayModeState
        }
        .onChange(of: listDisplayModeState) { _, _ in
            listDisplayMode = listDisplayModeState
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
