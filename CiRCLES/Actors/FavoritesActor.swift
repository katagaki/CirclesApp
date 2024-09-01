//
//  FavoritesActor.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation

actor FavoritesActor {

    func all(authToken: OpenIDToken) async -> (items: [UserFavorites.Response.FavoriteItem], wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem]) {
        let request = urlRequestForReadersAPI(endpoint: "FavoriteCircles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Favorites response length: \(data.count)")
            if let favorites = try? JSONDecoder().decode(UserFavorites.self, from: data) {
                debugPrint("Decoded favorites")
                let items = favorites.response.list.sorted(by: {
                    $0.favorite.color.rawValue < $1.favorite.color.rawValue
                })
                var wcIDMappedItems: [Int: UserFavorites.Response.FavoriteItem] = [:]
                for favorite in items {
                    wcIDMappedItems[favorite.circle.webCatalogID] = favorite
                }
                return (items, wcIDMappedItems)
            }
        }
        return ([], [:])
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
                "memo": "CiRCLESにより追加されました。"
                ],
            authToken: authToken
        )

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Response length after attempting to add favorite: \(data.count)")
            if let response = try? JSONDecoder().decode(UserFavorite.self, from: data) {
                debugPrint("Decoded response")
                if response.status == "success" {
                    debugPrint("Favorite added successfully")
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
            debugPrint("Response length after attempting to delete favorite: \(data.count)")
            if let response = try? JSONDecoder().decode(UserResponse.self, from: data) {
                debugPrint("Decoded response")
                if response.status == "success" {
                    debugPrint("Favorite deleted successfully")
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
