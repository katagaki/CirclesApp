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

    @State var isPreparing: Bool = false

    @State var favoriteCircles: [ComiketCircle] = []
    @State var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            CircleGrid(circles: favoriteCircles,
                       favorites: favoriteItems,
                       namespace: favoritesNamespace) { circle in
                navigationManager.push(.circlesDetail(circle: circle), for: .favorites)
            }
            .navigationTitle("ViewTitle.Favorites")
            .overlay {
                if isPreparing {
                    ProgressView()
                }
            }
            .refreshable {
                Task.detached {
                    await reloadFavorites()
                }
            }
            .onChange(of: favorites.items) { _, _ in
                Task.detached {
                    await reloadFavorites()
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
        await MainActor.run {
            self.isPreparing = true
        }

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

        await MainActor.run {
            withAnimation(.snappy.speed(2.0)) {
                self.favoriteCircles = favoriteCircles
                self.favoriteItems = favoriteItems
                self.isPreparing = false
            }
        }
    }
}
