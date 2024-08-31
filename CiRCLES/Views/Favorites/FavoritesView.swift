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

    @State var favoriteCircles: [ComiketCircle] = []
    @State var favoriteItems: [Int: UserFavorites.Response.FavoriteItem] = [:]

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            CircleGrid(circles: favoriteCircles,
                       favorites: favoriteItems) { circle in
                navigationManager.push(.circlesDetail(circle: circle), for: .favorites)
            }
            .navigationTitle("ViewTitle.Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .circlesDetail(let circle): CircleDetailView(circle: circle)
                default: Color.clear
                }
            }
        }
        .task {
            if let token = authManager.token {
                await favorites.getAll(authToken: token)
                let favoriteItemsSorted = favorites.items.sorted(by: {
                    $0.favorite.color.rawValue < $1.favorite.color.rawValue
                })
                favoriteCircles.removeAll()
                favoriteItems.removeAll()
                for favorite in favoriteItemsSorted {
                    if let webCatalogCircle = database.circle(for: favorite.circle.webCatalogID) {
                        favoriteCircles.append(webCatalogCircle)
                        favoriteItems[webCatalogCircle.id] = favorite
                    }
                }
            }
        }
    }
}
