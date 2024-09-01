//
//  FavoritesManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import Foundation

@Observable
class FavoritesManager {
    var items: [UserFavorites.Response.FavoriteItem]?
    var wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]?

    func contains(webCatalogID: Int) -> Bool {
        if let items {
            return items.contains(where: { $0.circle.webCatalogID == webCatalogID})
        } else {
            return false
        }
    }
}
