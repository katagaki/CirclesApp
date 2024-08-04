//
//  UserFavorites.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

// swiftlint:disable nesting
struct UserFavorites: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let count: String
        let maxCount: String
        let list: [FavoriteItem]

        struct FavoriteItem: Codable {
            let circle: WebCatalogCircle
            let favorite: WebCatalogFavorite
        }

        enum CodingKeys: String, CodingKey {
            case count = "count"
            case maxCount = "maxcount"
            case list = "list"
        }
    }
}
// swiftlint:enable nesting
