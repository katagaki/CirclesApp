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

    @Namespace var circlesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.circles]) {
            ZStack(alignment: .center) {
                Group {
                    if let searchedCircles {
                        CircleGrid(circles: searchedCircles,
                                   favorites: favorites.wcIDMappedItems,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    } else {
                        CircleGrid(circles: displayedCircles,
                                   favorites: favorites.wcIDMappedItems,
                                   namespace: circlesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.Circles")
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                if (selectedGenre == nil && selectedBlock == nil) && searchedCircles == nil {
                    ContentUnavailableView(
                        "Circles.NoFilterSelected",
                        systemImage: "questionmark.square.dashed",
                        description: Text("Circles.NoFilterSelected.Description")
                    )
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
                    reloadDisplayedCircles()
                }
            }
            .onChange(of: selectedMap) { oldValue, newValue in
                if isInitialLoadCompleted {
                    selectedMapID = selectedMap?.id ?? 0
                    if oldValue != newValue && oldValue != nil {
                        selectedBlock = nil
                    } else {
                        reloadDisplayedCircles()
                    }
                }
            }
            .onChange(of: selectedBlock) { _, _ in
                if isInitialLoadCompleted {
                    selectedBlockID = selectedBlock?.id ?? 0
                    reloadDisplayedCircles()
                }
            }
            .onChange(of: selectedDate) { _, _ in
                if isInitialLoadCompleted {
                    selectedDateID = selectedDate?.id ?? 0
                    reloadDisplayedCircles()
                }
            }
            .onChange(of: searchTerm) { _, _ in
                searchCircles()
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

    func reloadDisplayedCircles() {
        debugPrint("Reloading displayed circles")
        var displayedCircles: [ComiketCircle]?
        if let selectedGenre {
            displayedCircles = database.circles(with: selectedGenre)
        }
        if let selectedBlock {
            let circlesInSelectedBlock = database.circles(in: selectedBlock)
            if displayedCircles == nil {
                displayedCircles = circlesInSelectedBlock
            } else {
                displayedCircles?.removeAll(where: {
                    !circlesInSelectedBlock.contains($0)
                })
            }
        }
        if let selectedDate {
            displayedCircles?.removeAll(where: { $0.day != selectedDate.id })
        }

        withAnimation(.snappy.speed(2.0)) {
            self.displayedCircles = displayedCircles ?? []
        }
    }

    func searchCircles() {
        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            searchedCircles = database.circles(containing: searchTerm)
        } else {
            searchedCircles = nil
        }
    }
}
