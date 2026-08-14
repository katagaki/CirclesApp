//
//  UserFavorites.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/08/04.
//

// swiftlint:disable nesting
public struct UserFavorites: Codable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let count: Int
        public let maxCount: Int
        public let list: [FavoriteItem]

        public struct FavoriteItem: Codable, Hashable, Sendable {
            public let circle: WebCatalogCircle
            public let favorite: WebCatalogFavorite

            public init(circle: WebCatalogCircle, favorite: WebCatalogFavorite) {
                self.circle = circle
                self.favorite = favorite
            }
        }

        enum CodingKeys: String, CodingKey {
            case count = "count"
            case maxCount = "maxcount"
            case list = "list"
        }
    }
}
// swiftlint:enable nesting
