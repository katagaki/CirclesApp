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

    func add(
        _ circle: ComiketCircle,
        using extendedInformation: ComiketCircleExtendedInformation,
        to color: WebCatalogColor,
        authToken: OpenIDToken
    ) async {
        var request = urlRequestForReadersAPI(endpoint: "Favorite", authToken: authToken)

        let favorite = WebCatalogFavorite.Request(
            webCatalogID: extendedInformation.webCatalogID,
            color: color,
            memo: ""
        )

        request.httpBody = try? JSONEncoder().encode(favorite)

        if let (data, _) = try? await URLSession.shared.data(for: request) {
            debugPrint("Response length after attempting to add favorite: \(data.count)")
            if let response = try? JSONDecoder().decode(UserFavorites.self, from: data) {
                debugPrint("Decoded response")
                if response.status == "success" {
                    debugPrint("Favorite added successfully")
                }
            }
        }
    }

    func urlRequestForReadersAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/Readers/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
