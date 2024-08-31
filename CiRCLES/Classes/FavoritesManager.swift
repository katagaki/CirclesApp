//
//  FavoritesManager.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

import Foundation

@Observable
@MainActor
class FavoritesManager {
    var items: [UserFavorites.Response.FavoriteItem] = []

    func getAll(authToken: OpenIDToken) async {
        let request = urlRequestForReadersAPI(endpoint: "FavoriteCircles", authToken: authToken)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Favorites response length: \(data.count)")
            if let favorites = try? JSONDecoder().decode(UserFavorites.self, from: data) {
                debugPrint("Decoded favorites")
                self.items = favorites.response.list
            }
        }
    }

    func contains(_ extendedInformation: ComiketCircleExtendedInformation?) -> Bool {
        if let extendedInformation {
            return items.contains(where: { $0.circle.webCatalogID == extendedInformation.webCatalogID})
        } else {
            return false
        }
    }

    func add(
        _ circle: ComiketCircle,
        using extendedInformation: ComiketCircleExtendedInformation,
        to color: WebCatalogColor,
        authToken: OpenIDToken
    ) async {
        let request = urlRequestForReadersAPI(
            endpoint: "Favorite",
            parameters: [
                "access_token": authToken.accessToken,
                "wcid": String(extendedInformation.webCatalogID),
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
                    await getAll(authToken: authToken)
                }
            }
        }
    }

    func delete(
        using extendedInformation: ComiketCircleExtendedInformation,
        authToken: OpenIDToken
    ) async {
        let request = urlRequestForReadersAPI(
            endpoint: "Favorite",
            method: "DELETE",
            parameters: [
                "access_token": authToken.accessToken,
                "wcid": String(extendedInformation.webCatalogID)
                ],
            authToken: authToken
        )

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Response length after attempting to delete favorite: \(data.count)")
            if let response = try? JSONDecoder().decode(UserFavorite.self, from: data) {
                debugPrint("Decoded response")
                if response.status == "success" {
                    debugPrint("Favorite deleted successfully")
                    await getAll(authToken: authToken)
                }
            }
        }
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
