//
//  WebCatalogFavorite.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/08/04.
//

// swiftlint:disable nesting
public struct WebCatalogFavorite: Codable, Hashable, Sendable {
    public let webCatalogID: Int
    public let circleName: String
    public let color: WebCatalogColor
    public let memo: String?
    public let free: String?
    public let updateDate: String

    public init(webCatalogID: Int, circleName: String, color: WebCatalogColor,
                memo: String?, free: String?, updateDate: String) {
        self.webCatalogID = webCatalogID
        self.circleName = circleName
        self.color = color
        self.memo = memo
        self.free = free
        self.updateDate = updateDate
    }

    public struct Request: Codable, Sendable {
        public let webCatalogID: Int
        public let color: WebCatalogColor
        public let memo: String

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

    public static func == (lhs: WebCatalogFavorite, rhs: WebCatalogFavorite) -> Bool {
        return lhs.webCatalogID == rhs.webCatalogID
    }
}
// swiftlint:enable nesting
