import Foundation
import SwiftData

import SwiftUI

@Observable
class Favorites {
    var items: [UserFavorites.Response.FavoriteItem]?
    var wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]?

    var circles: [String: [ComiketCircle]]?

    var isGroupedByColor: Bool = true
    // Display modes are now handled by views via AppStorage

    var invalidationID: String = ""

    init() {
        let defaults = UserDefaults.standard
        self.isGroupedByColor = defaults.object(forKey: "Favorites.GroupByColor") as? Bool ?? true
    }

    static func mapped(
        using favoriteItems: [UserFavorites.Response.FavoriteItem],
        database: Database
    ) async -> [Int: [Int]] {
        let favoriteItemsSorted: [Int: [UserFavorites.Response.FavoriteItem]] = favoriteItems.reduce(
            into: [Int: [UserFavorites.Response.FavoriteItem]]()
        ) { partialResult, favoriteItem in
            partialResult[favoriteItem.favorite.color.rawValue, default: []].append(favoriteItem)
        }

        let actor = DataFetcher(database: await database.getTextDatabase())
        var favoriteCircleIdentifiers: [Int: [Int]] = [:]
        for colorKey in favoriteItemsSorted.keys {
            if let favoriteItems = favoriteItemsSorted[colorKey] {
                favoriteCircleIdentifiers[colorKey] = await actor.circles(forFavorites: favoriteItems)
            }
        }
        return favoriteCircleIdentifiers
    }

    func contains(webCatalogID: Int) -> Bool {
        if let items {
            return items.contains(where: { $0.circle.webCatalogID == webCatalogID})
        } else {
            return false
        }
    }
}
