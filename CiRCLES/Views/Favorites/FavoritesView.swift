//
//  FavoritesView.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(AuthManager.self) var authManager
    @Environment(FavoritesManager.self) var favorites
    @Environment(DatabaseManager.self) var database

    @State var isRefreshing: Bool = false

    @State var favoriteCircles: [ComiketCircle]?

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            ZStack(alignment: .center) {
                if !isRefreshing, let favoriteCircles {
                    if favoriteCircles.count == 0 {
                        ContentUnavailableView(
                            "Favorites.NoFavorites",
                            systemImage: "star.leadinghalf.filled",
                            description: Text("Favorites.NoFavorites.Description")
                        )
                    } else {
                        CircleGrid(circles: favoriteCircles,
                                   favorites: favorites.wcIDMappedItems,
                                   namespace: favoritesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .favorites)
                        }
                    }
                } else {
                    ProgressView("Favorites.Loading")
                }
            }
            .navigationTitle("ViewTitle.Favorites")
            .refreshable {
                Task.detached {
                    await reloadFavorites()
                }
            }
            .onAppear {
                if favoriteCircles == nil, let favoriteItems = favorites.items {
                    Task.detached {
                        await prepareCircles(using: favoriteItems)
                    }
                }
            }
            .onChange(of: favorites.items) { _, _ in
                debugPrint("Preparing favorites")
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
            var (items, wcIDMappedItems) = await actor.all(authToken: token)
            await MainActor.run {
                favorites.items = items
                favorites.wcIDMappedItems = wcIDMappedItems
            }
        }
    }

    func prepareCircles(using favoriteItems: [UserFavorites.Response.FavoriteItem]) async {
        var favoriteCircles: [ComiketCircle] = []
        let favoriteItemsSorted: [Int: [UserFavorites.Response.FavoriteItem]] = favoriteItems.reduce(
            into: [Int: [UserFavorites.Response.FavoriteItem]]()
        ) { partialResult, favoriteItem in
            if partialResult[favoriteItem.favorite.color.rawValue] != nil {
                partialResult[favoriteItem.favorite.color.rawValue]?.append(favoriteItem)
            } else {
                partialResult[favoriteItem.favorite.color.rawValue] = [favoriteItem]
            }
        }
        for colorKey in favoriteItemsSorted.keys.sorted() {
            if let favoriteItems = favoriteItemsSorted[colorKey] {
                var circles: [ComiketCircle] = []
                for favorite in favoriteItems {
                    if let webCatalogCircle = database.circle(for: favorite.circle.webCatalogID) {
                        circles.append(webCatalogCircle)
                    }
                }
                circles.sort(by: {$0.id < $1.id})
                favoriteCircles.append(contentsOf: circles)
            }
        }
        await MainActor.run {
            withAnimation(.snappy.speed(2.0)) {
                self.favoriteCircles = favoriteCircles
            }
        }
    }
}
