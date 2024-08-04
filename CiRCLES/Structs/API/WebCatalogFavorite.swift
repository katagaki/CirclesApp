//
//  WebCatalogFavorite.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

struct WebCatalogFavorite: Codable {
    let webCatalogID: Int
    let circleName: String
    let color: WebCatalogColor
    let memo: String
    let free: String
    let updateDate: String

    enum CodingKeys: String, CodingKey {
        case webCatalogID = "wcid"
        case circleName = "circle_name"
        case color = "color"
        case memo = "memo"
        case free = "free"
        case updateDate = "update_date"
    }
}
