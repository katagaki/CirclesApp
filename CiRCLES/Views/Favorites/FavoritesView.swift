//
//  FavoritesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftData
import SwiftUI

struct FavoritesView: View {

    @EnvironmentObject var navigator: Navigator
    @Environment(AuthManager.self) var authManager
    @Environment(Favorites.self) var favorites
    @Environment(Database.self) var database

    @Environment(\.modelContext) var modelContext

    @State var favoriteCircles: [String: [ComiketCircle]]?

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigator[.favorites]) {
            ZStack(alignment: .center) {
                if let favoriteCircles {
                    ColorGroupedCircleGrid(
                        groups: favoriteCircles,
                        showsOverlayWhenEmpty: false,
                        namespace: favoritesNamespace
                    ) { circle in
                        navigator.push(.circlesDetail(circle: circle), for: .favorites)
                    }
                       .overlay {
                           if favoriteCircles.isEmpty {
                               ContentUnavailableView(
                                   "Favorites.NoFavorites",
                                   systemImage: "star.leadinghalf.filled",
                                   description: Text("Favorites.NoFavorites.Description")
                               )
                           }
                       }
                } else {
                    ProgressView("Favorites.Loading")
                }
            }
            .navigationTitle("ViewTitle.Favorites")
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarBackground(.automatic, for: .tabBar)
            .refreshable {
                await reloadFavorites()
            }
            .onAppear {
                if authManager.onlineState == .offline {
                    favoriteCircles = [:]
                } else {
                    if favoriteCircles == nil, let favoriteItems = favorites.items {
                        Task.detached {
                            await prepareCircles(using: favoriteItems)
                        }
                    }
                }
            }
            .onChange(of: favorites.items) { _, _ in
                if let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle):
                    CircleDetailView(circle: circle)
                        .automaticNavigationTransition(id: circle.id, in: favoritesNamespace)
                default: Color.clear
                }
            }
        }
    }

    func reloadFavorites() async {
        if let token = authManager.token {
            let actor = FavoritesActor()
            let (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func prepareCircles(using favoriteItems: [UserFavorites.Response.FavoriteItem]) async {
        let favoriteItemsSorted: [Int: [UserFavorites.Response.FavoriteItem]] = favoriteItems.reduce(
            into: [Int: [UserFavorites.Response.FavoriteItem]]()
        ) { partialResult, favoriteItem in
            partialResult[favoriteItem.favorite.color.rawValue, default: []].append(favoriteItem)
        }

        let actor = DataFetcher(modelContainer: sharedModelContainer)
        var favoriteCircleIdentifiers: [Int: [PersistentIdentifier]] = [:]
        for colorKey in favoriteItemsSorted.keys {
            if let favoriteItems = favoriteItemsSorted[colorKey] {
                favoriteCircleIdentifiers[colorKey] = await actor.circles(forFavorites: favoriteItems)
            }
        }
        await MainActor.run {
            var favoriteCircles: [String: [ComiketCircle]] = [:]
            for colorKey in favoriteCircleIdentifiers.keys.sorted() {
                if let circleIdentifiers = favoriteCircleIdentifiers[colorKey] {
                    var circles = database.circles(circleIdentifiers)
                    circles.sort(by: {$0.id < $1.id})
                    favoriteCircles[String(colorKey)] = circles
                }
            }
            withAnimation(.snappy.speed(2.0)) {
                self.favoriteCircles = favoriteCircles
            }
        }
    }
}
