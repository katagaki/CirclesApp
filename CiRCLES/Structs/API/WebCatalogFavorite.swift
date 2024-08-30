//
//  WebCatalogFavorite.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

// swiftlint:disable nesting
struct WebCatalogFavorite: Codable, Hashable {
    let webCatalogID: Int
    let circleName: String
    let color: WebCatalogColor
    let memo: String?
    let free: String?
    let updateDate: String

    struct Request: Codable {
        let webCatalogID: Int
        let color: WebCatalogColor
        let memo: String

        enum CodingKeys: String, CodingKey {
            case webCatalogID = "wcid"
            case color = "color"
            case memo = "memo"
        }
    }

    enum CodingKeys: String, CodingKey {
        case webCatalogID = "wcid"
        case circleName = "circle_name"
        case color = "color"
        case memo = "memo"
        case free = "free"
        case updateDate = "update_date"
    }

    static func == (lhs: WebCatalogFavorite, rhs: WebCatalogFavorite) -> Bool {
        return lhs.webCatalogID == rhs.webCatalogID
    }
}
// swiftlint:enable nesting
