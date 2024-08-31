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

    @State var isPreparing: Bool = true

    @State var favoriteCircles: [ComiketCircle] = []
    @State var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            ZStack(alignment: .center) {
                if isPreparing {
                    ProgressView("Favorites.Loading")
                } else {
                    if favoriteCircles.count == 0 {
                        ContentUnavailableView(
                            "Favorites.NoFavorites",
                            systemImage: "star.leadinghalf.filled",
                            description: Text("Favorites.NoFavorites.Description")
                        )
                    } else {
                        CircleGrid(circles: favoriteCircles,
                                   favorites: favoriteItems,
                                   namespace: favoritesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .favorites)
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.Favorites")
            .refreshable {
                if let token = authManager.token {
                    withAnimation(.snappy.speed(2.0)) {
                        self.isPreparing = true
                    }
                    Task.detached {
                        await favorites.getAll(authToken: token)
                        await reloadFavorites()
                        await MainActor.run {
                            withAnimation(.snappy.speed(2.0)) {
                                self.isPreparing = false
                            }
                        }
                    }
                }
            }
            .onChange(of: favorites.items) { _, _ in
                Task.detached {
                    await reloadFavorites()
                    await MainActor.run {
                        withAnimation(.snappy.speed(2.0)) {
                            self.isPreparing = false
                        }
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

    func reloadFavorites() {
        debugPrint("Reloading favorites")

        let favoriteItemsSorted = favorites.items.sorted(by: {
            $0.favorite.color.rawValue < $1.favorite.color.rawValue
        })
        var favoriteCircles: [ComiketCircle] = []
        var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]
        for favorite in favoriteItemsSorted {
            if let webCatalogCircle = database.circle(for: favorite.circle.webCatalogID) {
                favoriteCircles.append(webCatalogCircle)
                favoriteItems[webCatalogCircle.id] = favorite
            }
        }

        self.favoriteCircles = favoriteCircles
        self.favoriteItems = favoriteItems
    }
}
