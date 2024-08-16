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

    var body: some View {
        NavigationStack(path: $navigationManager[.favorites]) {
            List(favorites.items, id: \.circle.webCatalogID) { favorite in
                Text(favorite.circle.name)
            }
            .navigationTitle("ViewTitle.Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if let token = authManager.token {
                await favorites.getAll(authToken: token)
            }
        }
    }
}
