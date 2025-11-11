//
//  FavoritesCache.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import SwiftData
import SwiftUI

@Observable
class FavoritesCache {
    var circles: [String: [ComiketCircle]]?

    var isVisitModeOn: Bool = false
    var isGroupedByColor: Bool = true

    var isInitialLoadCompleted: Bool = false

    static func mapped(
        using favoriteItems: [UserFavorites.Response.FavoriteItem]
    ) async -> [Int: [PersistentIdentifier]] {
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
        return favoriteCircleIdentifiers
    }
}
