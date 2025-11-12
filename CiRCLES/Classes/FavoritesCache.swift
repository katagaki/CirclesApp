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

    var invalidationID: String = ""

    init() {
        let defaults = UserDefaults.standard
        self.isVisitModeOn = defaults.object(forKey: "Favorites.VisitModeOn") as? Bool ?? false
        self.isGroupedByColor = defaults.object(forKey: "Favorites.GroupByColor") as? Bool ?? true
    }

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
