//
//  CirclesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Komponents
import SwiftUI

struct CirclesView: View {

    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(CatalogManager.self) var catalog
    @Environment(DatabaseManager.self) var database

    @State var displayedCircles: [ComiketCircle] = []
    @State var searchedCircles: [ComiketCircle]?
    @State var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]
    
    @State var selectedGenre: ComiketGenre?
    @State var selectedMap: ComiketMap?
    @State var selectedBlock: ComiketBlock?
    @State var selectedDate: ComiketDate?

    @State var searchTerm: String = ""

    var body: some View {
        NavigationStack(path: $navigationManager[.circles]) {
            Group {
                if let searchedCircles {
                    CircleGrid(circles: searchedCircles,
                               favorites: favoriteItems) { circle in
                        navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                    }
                } else {
                    CircleGrid(circles: displayedCircles,
                               favorites: favoriteItems) { circle in
                        navigationManager.push(.circlesDetail(circle: circle), for: .circles)
                    }
                }
            }
            .navigationTitle("ViewTitle.Circles")
            .toolbarBackground(.hidden, for: .tabBar)
            .overlay {
                if selectedGenre == nil && selectedBlock == nil {
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
                                             icon: "theatermask.and.paintbrush") {
                                Picker(selection: $selectedGenre.animation(.snappy.speed(2.0))) {
                                    Text("Shared.All")
                                        .tag(nil as ComiketGenre?)
                                    ForEach(database.genres(), id: \.id) { genre in
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
                                    ForEach(database.maps(), id: \.id) { map in
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
                                    ForEach(database.dates(), id: \.id) { date in
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
            .onChange(of: selectedGenre) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: selectedBlock) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: selectedDate) { _, _ in
                reloadDisplayedCircles()
            }
            .onChange(of: searchTerm) { _, _ in
                searchCircles()
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
    }

    func reloadDisplayedCircles() {
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

        var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]
        for displayedCircle in displayedCircles ?? [] {
            if let favoriteForDisplayedCircle = favorites.items.first(where: {
                $0.circle.webCatalogID == displayedCircle.extendedInformation?.webCatalogID
            }) {
                favoriteItems[displayedCircle.id] = favoriteForDisplayedCircle
            }
        }

        withAnimation(.snappy.speed(2.0)) {
            self.favoriteItems = favoriteItems
            self.displayedCircles = displayedCircles ?? []
        }
    }

    func searchCircles() {
        if searchTerm.trimmingCharacters(in: .whitespaces).count > 2 {
            searchedCircles = database.circles(containing: searchTerm)
        } else {
            searchedCircles = nil
        }
    }
}
