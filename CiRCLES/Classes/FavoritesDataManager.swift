//
//  FavoritesDataManager.swift
//  CiRCLES
//
//  Created by GitHub Copilot on 2024/11/08.
//

import Foundation
import SwiftData

@Observable
@MainActor
class FavoritesDataManager {
    
    // Cache for favorite circles grouped by color
    private var cachedFavoriteCircles: [String: [String: [ComiketCircle]]] = [:]
    
    // Track if initial load has been completed
    var isInitialLoadCompleted: Bool = false
    
    func circles(for favoriteItems: [UserFavorites.Response.FavoriteItem], dateID: Int?, database: Database) async -> [String: [ComiketCircle]] {
        let cacheKey = makeCacheKey(favoriteItems: favoriteItems, dateID: dateID)
        
        // Return cached data if available
        if let cached = cachedFavoriteCircles[cacheKey] {
            return cached
        }
        
        // Otherwise, load from database
        let circles = await loadFavoriteCircles(favoriteItems: favoriteItems, dateID: dateID, database: database)
        cachedFavoriteCircles[cacheKey] = circles
        return circles
    }
    
    private func loadFavoriteCircles(favoriteItems: [UserFavorites.Response.FavoriteItem], dateID: Int?, database: Database) async -> [String: [ComiketCircle]] {
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
        
        var favoriteCircles: [String: [ComiketCircle]] = [:]
        for colorKey in favoriteCircleIdentifiers.keys.sorted() {
            if let circleIdentifiers = favoriteCircleIdentifiers[colorKey] {
                var circles = database.circles(circleIdentifiers)
                circles.sort(by: {$0.id < $1.id})
                if let dateID {
                    favoriteCircles[String(colorKey)] = circles.filter({
                        $0.day == dateID
                    })
                } else {
                    favoriteCircles[String(colorKey)] = circles
                }
            }
        }
        return favoriteCircles
    }
    
    private func makeCacheKey(favoriteItems: [UserFavorites.Response.FavoriteItem], dateID: Int?) -> String {
        let itemIDs = favoriteItems.map { $0.circle.webCatalogID }.sorted().map(String.init).joined(separator: ",")
        return "\(itemIDs)_\(dateID ?? -1)"
    }
    
    func clearCache() {
        cachedFavoriteCircles.removeAll()
        isInitialLoadCompleted = false
    }
}
