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
    @State var isPreparingCircles: Bool = false

    @Namespace var favoritesNamespace

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            ZStack(alignment: .center) {
                if favorites.isRefreshing || !favorites.isFirstRefreshComplete || isPreparingCircles {
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
                                   favorites: favorites.wcIDMappedItems,
                                   namespace: favoritesNamespace) { circle in
                            navigationManager.push(.circlesDetail(circle: circle), for: .favorites)
                        }
                    }
                }
            }
            .navigationTitle("ViewTitle.Favorites")
            .refreshable {
                if let token = authManager.token {
                    Task.detached {
                        await favorites.getAll(authToken: token)
                    }
                }
            }
            .onChange(of: favorites.items) { _, _ in
                debugPrint("Reloading favorites")
                withAnimation(.snappy.speed(2.0)) {
                    isPreparingCircles = true
                }
                favoriteCircles.removeAll()
                for favorite in favorites.items {
                    if let webCatalogCircle = database.circle(for: favorite.circle.webCatalogID) {
                        favoriteCircles.append(webCatalogCircle)
                    }
                }
                withAnimation(.snappy.speed(2.0)) {
                    isPreparingCircles = false
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
}
