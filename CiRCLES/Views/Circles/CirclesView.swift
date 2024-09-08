//
//  CirclesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftData
import SwiftUI

struct CirclesView: View {

    @EnvironmentObject var navigator: Navigator
    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database

    @Environment(\.modelContext) var modelContext

    @Query(sort: [SortDescriptor(\ComiketDate.id, order: .forward)])
    var dates: [ComiketDate]

    @Query(sort: [SortDescriptor(\ComiketMap.id, order: .forward)])
    var maps: [ComiketMap]

    @Query(sort: [SortDescriptor(\ComiketGenre.id, order: .forward)])
    var genres: [ComiketGenre]

    @Query(sort: [SortDescriptor(\ComiketBlock.id, order: .forward)])
    var blocks: [ComiketBlock]

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?

    @State var selectedGenre: ComiketGenre?
    @State var selectedMap: ComiketMap?
    @State var selectedBlock: ComiketBlock?
    @State var selectedDate: ComiketDate?

    @State var blocksInMap: [ComiketBlock] = []

    @State var searchTerm: String = ""

    @State var isInitialLoadCompleted: Bool = false

    @AppStorage(wrappedValue: CircleDisplayMode.grid, "Circles.DisplayMode") var displayMode: CircleDisplayMode
    @AppStorage(wrappedValue: ListDisplayMode.regular, "Circles.ListSize") var listDisplayMode: ListDisplayMode
    @State var displayModeState: CircleDisplayMode = .grid
    @State var listDisplayModeState: ListDisplayMode = .regular

    @Namespace var circlesNamespace

    var genreMapBlockDate: [Int?] {[
        selectedGenre?.id,
        selectedMap?.id,
        selectedBlock?.id,
        selectedDate?.id
    ]}

    var body: some View {
        NavigationStack(path: $navigator[.circles]) {
            ZStack(alignment: .center) {
                switch displayModeState {
                case .grid:
                    if let searchedCircles {
                        CircleGrid(circles: searchedCircles,
                                   namespace: circlesNamespace) { circle in
                            navigator.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    } else {
                        CircleGrid(circles: displayedCircles,
                                   namespace: circlesNamespace) { circle in
                            navigator.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    }
                case .list:
                    if let searchedCircles {
                        CircleList(circles: searchedCircles,
                                   displayMode: listDisplayModeState,
                                   namespace: circlesNamespace) { circle in
                            navigator.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    } else {
                        CircleList(circles: displayedCircles,
                                   displayMode: listDisplayModeState,
                                   namespace: circlesNamespace) { circle in
                            navigator.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    }
                }
                if (selectedGenre == nil && selectedMap == nil) && searchedCircles == nil {
                    ContentUnavailableView(
                        "Circles.NoFilterSelected",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Circles.NoFilterSelected.Description")
                    )
                }
            }
            .navigationTitle("ViewTitle.Circles")
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if displayModeState == .list {
                            Button {
                                withAnimation(.snappy.speed(2.0)) {
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
                        Button {
                            withAnimation(.snappy.speed(2.0)) {
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
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    CircleFilterBar(
                        selectedGenre: $selectedGenre,
                        selectedMap: $selectedMap,
                        selectedBlock: $selectedBlock,
                        selectedDate: $selectedDate
                    )
                }
            }
            .searchable(text: $searchTerm,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Circles.Search.Prompt")
            .onAppear {
                if !isInitialLoadCompleted {
                    debugPrint("Restoring Circles view state")
                    displayModeState = displayMode
                    listDisplayModeState = listDisplayMode
                    isInitialLoadCompleted = true
                }
            }
            .onChange(of: genreMapBlockDate) { _, _ in
                if isInitialLoadCompleted {
                    Task.detached {
                        await reloadDisplayedCircles()
                    }
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
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle):
                    CircleDetailView(circle: circle)
                        .automaticNavigationTransition(id: circle.id, in: circlesNamespace)
                default: Color.clear
                }
            }
        }
    }

    func reloadDisplayedCircles() async {
        debugPrint("Reloading displayed circles")
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleIdentifiersByGenre: [PersistentIdentifier]?
        var circleIdentifiersByMap: [PersistentIdentifier]?
        var circleIdentifiersByBlock: [PersistentIdentifier]?
        var circleIdentifiers: [PersistentIdentifier] = []

        if let selectedGenre {
            circleIdentifiersByGenre = await actor.circles(withGenre: selectedGenre.id)
        }
        if let selectedMap {
            circleIdentifiersByMap = await actor.circles(inMap: selectedMap.id)
            if let selectedBlock {
                circleIdentifiersByBlock = await actor.circles(inBlock: selectedBlock.id)
            }
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
            if let selectedDate {
                displayedCircles.removeAll(where: { $0.day != selectedDate.id })
            }
            withAnimation(.snappy.speed(2.0)) {
                self.displayedCircles = displayedCircles
            }
        }
    }

    func searchCircles() async {
        debugPrint("Reloading searched circles")
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)
            await MainActor.run {
                let searchedCircles = database.circles(circleIdentifiers)
                withAnimation(.snappy.speed(2.0)) {
                    self.searchedCircles = searchedCircles
                }
            }
        } else {
            await MainActor.run {
                withAnimation(.snappy.speed(2.0)) {
                    searchedCircles = nil
                }
            }
        }
    }
}
