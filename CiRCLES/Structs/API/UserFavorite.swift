//
//  UserFavorite.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/30.
//

// swiftlint:disable nesting
struct UserFavorite: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let circle: WebCatalogCircle
        let favorite: WebCatalogFavorite
    }
}
// swiftlint:enable nesting
