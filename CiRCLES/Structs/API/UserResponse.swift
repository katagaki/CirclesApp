//
//  UserResponse.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/31.
//

struct UserResponse: Codable {
    let status: String
    let response: Response?

    struct Response: Codable {
        let circle: WebCatalogCircle?
        let favorite: WebCatalogFavorite?
    }
}
