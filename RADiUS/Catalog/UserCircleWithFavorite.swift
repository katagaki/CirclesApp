//
//  UserCircleWithFavorite.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/08/30.
//

public struct UserCircleWithFavorite: Codable, Sendable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let circle: WebCatalogCircle?
        public let favorite: WebCatalogFavorite?
    }
}
