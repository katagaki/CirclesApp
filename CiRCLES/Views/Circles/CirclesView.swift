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

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

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
    @State var circleSpaceMappings: [Int: String] = [:]

    @AppStorage(wrappedValue: 0, "Circles.SelectedGenreID") var selectedGenreID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedMapID") var selectedMapID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedBlockID") var selectedBlockID: Int
    @AppStorage(wrappedValue: 0, "Circles.SelectedDateID") var selectedDateID: Int

    @State var selectedGenre: ComiketGenre?
    @State var selectedMap: ComiketMap?
    @State var selectedBlock: ComiketBlock?
    @State var selectedDate: ComiketDate?

    @State var searchTerm: String = ""

    @State var isInitialLoadCompleted: Bool = false

    @AppStorage(wrappedValue: CircleDisplayMode.grid, "Circles.DisplayMode") var displayMode: CircleDisplayMode
    @State var displayModeState: CircleDisplayMode = .grid

    @Namespace var circlesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.circles]) {
            ZStack(alignment: .center) {
                switch displayModeState {
                case .grid:
                    if let searchedCircles {
                        CircleGrid(circles: searchedCircles,
                                   spaceMappings: circleSpaceMappings,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    } else {
                        CircleGrid(circles: displayedCircles,
                                   spaceMappings: circleSpaceMappings,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    }
                case .list:
                    if let searchedCircles {
                        CircleList(circles: searchedCircles,
                                   spaceMappings: circleSpaceMappings,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    } else {
                        CircleList(circles: displayedCircles,
                                   spaceMappings: circleSpaceMappings,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    }
                }
                if (selectedGenre == nil && selectedBlock == nil) && searchedCircles == nil {
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
                            Label("Shared.DisplayMode.Grid", systemImage: "rectangle.grid.3x2")
                        case .list:
                            Label("Shared.DisplayMode.List", systemImage: "rectangle.grid.1x2")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BarAccessory(placement: .bottom) {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0) {
                            BarAccessoryMenu(LocalizedStringKey(selectedGenre?.name ?? "Shared.Genre"),
                                             icon: (selectedGenre?.name == "ブルーアーカイブ" ?
                                                    "scope" : "theatermask.and.paintbrush")) {
                                Picker(selection: $selectedGenre.animation(.snappy.speed(2.0))) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketGenre?)
                                    ForEach(genres) { genre in
                                        Text(genre.name)
                                            .tag(genre)
                                    }
                                } label: {
                                    Text("Shared.Genre")
                                }
                            }
                            BarAccessoryMenu(LocalizedStringKey(selectedMap?.name ?? "Shared.Map"),
                                             icon: "map") {
                                Picker(selection: $selectedMap.animation(.snappy.speed(2.0))) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketMap?)
                                    ForEach(maps) { map in
                                        Text(map.name)
                                            .tag(map)
                                    }
                                } label: {
                                    Text("Shared.Map")
                                }
                            }
                            if let selectedMap {
                                BarAccessoryMenu(LocalizedStringKey(selectedBlock?.name ?? "Shared.Block"),
                                                 icon: "table.furniture") {
                                    Picker(selection: $selectedBlock.animation(.snappy.speed(2.0))) {
                                        Text("Shared.All")
                                            .tag(nil as ComiketBlock?)
                                        ForEach(database.blocks(in: selectedMap), id: \.id) { block in
                                            Text(block.name)
                                                .tag(block)
                                        }
                                    } label: {
                                        Text("Shared.Block")
                                    }
                                }
                            }
                            BarAccessoryMenu((selectedDate != nil ? "Shared.\(selectedDate!.id)th.Day" : "Shared.Day"),
                                             icon: "calendar") {
                                Picker(selection: $selectedDate.animation(.snappy.speed(2.0))) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketDate?)
                                    ForEach(dates) { date in
                                        Text("Shared.\(date.id)th.Day")
                                            .tag(date)
                                    }
                                } label: {
                                    Text("Shared.Day")
                                }
                            }
                        }
                        .padding([.leading, .trailing], 12.0)
                        .padding([.top, .bottom], 12.0)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .searchable(text: $searchTerm,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Circles.Search.Prompt")
            .onAppear {
                if !isInitialLoadCompleted {
                    debugPrint("Restoring Circles view state")
                    displayModeState = displayMode
                    selectedGenre = genres.first(where: {$0.id == selectedGenreID})
                    selectedMap = maps.first(where: {$0.id == selectedMapID})
                    selectedBlock = blocks.first(where: {$0.id == selectedBlockID})
                    selectedDate = dates.first(where: {$0.id == selectedDateID})
                    isInitialLoadCompleted = true
                }
            }
            .onChange(of: selectedGenre) { _, _ in
                if isInitialLoadCompleted {
                    selectedGenreID = selectedGenre?.id ?? 0
                    reloadAll()
                }
            }
            .onChange(of: selectedMap) { oldValue, newValue in
                if isInitialLoadCompleted {
                    selectedMapID = selectedMap?.id ?? 0
                    if oldValue != newValue && oldValue != nil {
                        selectedBlock = nil
                    } else {
                        reloadAll()
                    }
                }
            }
            .onChange(of: selectedBlock) { _, _ in
                if isInitialLoadCompleted {
                    selectedBlockID = selectedBlock?.id ?? 0
                    reloadAll()
                }
            }
            .onChange(of: selectedDate) { _, _ in
                if isInitialLoadCompleted {
                    selectedDateID = selectedDate?.id ?? 0
                    reloadAll()
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

    func reloadAll() {
        Task.detached {
            await reloadDisplayedCircles()
            await reloadMappings()
        }
    }

    func reloadDisplayedCircles() async {
        debugPrint("Reloading displayed circles")
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleIdentifiers: [PersistentIdentifier]?
        if let selectedGenre {
            let selectedGenreID = selectedGenre.id
            circleIdentifiers = await actor.circles(withGenre: selectedGenreID)
        }
        if let selectedBlock {
            let selectedBlockID = selectedBlock.id
            let circleIdentifiersInSelectedBlock = await actor.circles(inBlock: selectedBlockID)
            if circleIdentifiers == nil {
                circleIdentifiers = circleIdentifiersInSelectedBlock
            } else {
                circleIdentifiers?.removeAll(where: {
                    !circleIdentifiersInSelectedBlock.contains($0)
                })
            }
        }

        await MainActor.run {
            if let circleIdentifiers {
                var displayedCircles = database.circles(circleIdentifiers, in: modelContext)
                if let selectedDate {
                    displayedCircles.removeAll(where: { $0.day != selectedDate.id })
                }
                withAnimation(.snappy.speed(2.0)) {
                    self.displayedCircles = displayedCircles
                }
            } else {
                withAnimation(.snappy.speed(2.0)) {
                    self.displayedCircles = []
                }
            }
        }
    }

    func reloadMappings() async {
        debugPrint("Reloading circle ID to space name mapping")
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleSpaceMappings: [Int: String] = [:]
        // TODO: Cache this in a bigger context so that search can also use it with fast performance
        let circles = searchedCircles == nil ? displayedCircles : searchedCircles!
        for circle in circles {
            let circleID = circle.id
            let blockName = await actor.blockName(circle.blockID)
            if let blockName {
                circleSpaceMappings[circleID] = "\(blockName)\(circle.spaceNumberCombined())"
            }
        }

        await MainActor.run {
            self.circleSpaceMappings = circleSpaceMappings
        }
    }

    func searchCircles() async {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)

            await MainActor.run {
                let searchedCircles = database.circles(circleIdentifiers, in: modelContext)
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
