import Foundation
import SwiftData

import SwiftUI
import RADiUS
import AXiS

@Observable
class Favorites {
    var items: [UserFavorites.Response.FavoriteItem]?
    var wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]?

    var circles: [String: [ComiketCircle]]?

    var isGroupedByColor: Bool = true
    // Display modes are now handled by views via AppStorage

    var invalidationID: String = ""

    var isRefreshing: Bool = false

    /// Counts every change that came from circle.ms, so a refresh that started before a
    /// newer change landed can tell its result is out of date.
    @ObservationIgnored private var revision: Int = 0

    init() {
        let defaults = UserDefaults.standard
        self.isGroupedByColor = defaults.object(forKey: "Favorites.GroupByColor") as? Bool ?? true
    }

    /// Fills in the favourites from the cache when nothing has been loaded yet. The cache
    /// never replaces favourites that are already in memory, which are at least as new.
    @MainActor
    func loadFromCache() async {
        guard items == nil else { return }
        let actor = FavoritesActor(modelContainer: sharedModelContainer)
        let (items, wcIDMappedItems) = await actor.cached()
        guard self.items == nil else { return }
        self.items = items
        self.wcIDMappedItems = wcIDMappedItems
    }

    @MainActor
    func refresh(authToken: OpenIDToken?) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let startingRevision = revision
        let actor = FavoritesActor(modelContainer: sharedModelContainer)
        let (items, wcIDMappedItems) = await actor.all(authToken: authToken ?? OpenIDToken())
        if revision == startingRevision || self.items == nil {
            apply(items: items, wcIDMappedItems: wcIDMappedItems)
        }
        isRefreshing = false
    }

    @MainActor
    func apply(
        items: [UserFavorites.Response.FavoriteItem],
        wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]
    ) {
        revision += 1
        self.items = items
        self.wcIDMappedItems = wcIDMappedItems
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

    /// Whether there are any favourites to work with, which features built on them, such
    /// as route guidance, need before they are offered.
    var isAvailable: Bool {
        !(wcIDMappedItems?.isEmpty ?? true)
    }

    func contains(webCatalogID: Int) -> Bool {
        if let items {
            return items.contains(where: { $0.circle.webCatalogID == webCatalogID})
        } else {
            return false
        }
    }
}
