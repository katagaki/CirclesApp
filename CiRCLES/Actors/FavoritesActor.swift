//
//  FavoritesActor.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SwiftData

@ModelActor
actor FavoritesActor {

    func all(authToken: OpenIDToken) async -> (
        items: [UserFavorites.Response.FavoriteItem],
        wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]
    ) {
        let request = urlRequestForReadersAPI(endpoint: "FavoriteCircles", authToken: authToken)

        var wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem] = [:]
        var items: [UserFavorites.Response.FavoriteItem] = []
        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let favorites = try? JSONDecoder().decode(UserFavorites.self, from: data) {
                items = favorites.response.list.sorted(by: {
                    $0.favorite.color.rawValue < $1.favorite.color.rawValue
                })
                for favorite in items {
                    wcIDMappedItems[favorite.circle.webCatalogID] = favorite
                }
                try? modelContext.transaction {
                    try? modelContext.delete(model: CirclesFavorite.self)
                    wcIDMappedItems.keys.forEach { webCatalogID in
                        if let favoriteItem = wcIDMappedItems[webCatalogID] {
                            let favorite = CirclesFavorite(
                                webCatalogID: webCatalogID,
                                favoriteItem: favoriteItem
                            )
                            modelContext.insert(favorite)
                        }
                    }
                    try? modelContext.save()
                }
            }
        } else if let cachedFavorites: [CirclesFavorite] = try? modelContext.fetch(FetchDescriptor<CirclesFavorite>()) {
            items = cachedFavorites.map({ $0.favoriteItem() })
            for favorite in cachedFavorites {
                wcIDMappedItems[favorite.webCatalogID] = favorite.favoriteItem()
            }
        }
        return (items, wcIDMappedItems)
    }

    func add(
        _ webCatalogID: Int,
        to color: WebCatalogColor,
        authToken: OpenIDToken
    ) async -> Bool {
        let request = urlRequestForReadersAPI(
            endpoint: "Favorite",
            parameters: [
                "access_token": authToken.accessToken,
                "wcid": String(webCatalogID),
                "color": String(color.rawValue),
                "memo": ""
                ],
            authToken: authToken
        )

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let response = try? JSONDecoder().decode(UserCircleWithFavorite.self, from: data) {
                if response.status == "success" {
                    if let circle = response.response.circle,
                       let favorite = response.response.favorite {
                        let favoriteItem = UserFavorites.Response.FavoriteItem(
                            circle: circle, favorite: favorite
                        )
                        modelContext.insert(
                            CirclesFavorite(
                                webCatalogID: webCatalogID,
                                favoriteItem: favoriteItem
                            )
                        )
                    }
                    return true
                }
            }
        }
        return false
    }

    func delete(
        _ webCatalogID: Int,
        authToken: OpenIDToken
    ) async -> Bool {
        let request = urlRequestForReadersAPI(
            endpoint: "Favorite",
            method: "DELETE",
            parameters: [
                "access_token": authToken.accessToken,
                "wcid": String(webCatalogID)
                ],
            authToken: authToken
        )

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            if let response = try? JSONDecoder().decode(UserResponse.self, from: data) {
                if response.status == "success" {
                    let fetchDescriptor = FetchDescriptor<CirclesFavorite>(
                        predicate: #Predicate<CirclesFavorite> {
                            $0.webCatalogID == webCatalogID
                        }
                    )
                    if let matchedFavorites = try? modelContext.fetch(fetchDescriptor) {
                        try? modelContext.transaction {
                            matchedFavorites.forEach {
                                modelContext.delete($0)
                            }
                            try? modelContext.save()
                        }
                    }
                    return true
                }
            }
        }
        return false
    }

    func urlRequestForReadersAPI(
        endpoint: String,
        method: String = "POST",
        parameters: [String: String] = [:],
        authToken: OpenIDToken
    ) -> URLRequest {
        var endpointComponents = URLComponents(string: "\(circleMsAPIEndpoint)/Readers/\(endpoint)")!

        if parameters.keys.count > 0 {
            var queryItems: [URLQueryItem] = []
            for (key, value) in parameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            endpointComponents.queryItems = queryItems
        }

        if let endpoint = endpointComponents.url {
            var request = URLRequest(url: endpoint)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")
            return request
        } else {
            fatalError("Fatal error when trying to get URL request for Favorites API")
        }
    }
}
