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

    func urlRequestForReadersAPI(endpoint: String, authToken: OpenIDToken) -> URLRequest {
        let endpoint = URL(string: "\(circleMsAPIEndpoint)/Readers/\(endpoint)/")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken.accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
