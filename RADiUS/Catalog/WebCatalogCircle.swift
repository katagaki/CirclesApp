//
//  WebCatalogCircle.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/08/04.
//

public struct WebCatalogCircle: Codable, Hashable, Sendable {
    public let webCatalogID: Int
    public let name: String
    public let nameKana: String
    public let circlemsID: String
    public let cutURL: String
    public let cutBaseURL: String
    public let cutWebURL: String
    public let cutWebUpdateDate: String
    public let genre: String
    public let url: String
    public let pixivURL: String
    public let twitterURL: String
    public let clipStudioURL: String
    public let niconicoURL: String
    public let tag: String
    public let circleDescription: String
    public let onlineStores: [OnlineStore]
    public let updateID: String
    public let updateDate: String

    public struct OnlineStore: Codable, Hashable, Sendable {
        public let name: String
        public let link: String
    }

    public init(webCatalogID: Int, name: String, nameKana: String, circlemsID: String,
                cutURL: String, cutBaseURL: String, cutWebURL: String, cutWebUpdateDate: String,
                genre: String, url: String, pixivURL: String, twitterURL: String,
                clipStudioURL: String, niconicoURL: String, tag: String,
                circleDescription: String, onlineStores: [OnlineStore],
                updateID: String, updateDate: String) {
        self.webCatalogID = webCatalogID
        self.name = name
        self.nameKana = nameKana
        self.circlemsID = circlemsID
        self.cutURL = cutURL
        self.cutBaseURL = cutBaseURL
        self.cutWebURL = cutWebURL
        self.cutWebUpdateDate = cutWebUpdateDate
        self.genre = genre
        self.url = url
        self.pixivURL = pixivURL
        self.twitterURL = twitterURL
        self.clipStudioURL = clipStudioURL
        self.niconicoURL = niconicoURL
        self.tag = tag
        self.circleDescription = circleDescription
        self.onlineStores = onlineStores
        self.updateID = updateID
        self.updateDate = updateDate
    }

    enum CodingKeys: String, CodingKey {
        case webCatalogID = "wcid"
        case name
        case nameKana = "name_kana"
        case circlemsID = "circlemsId"
        case cutURL = "cut_url"
        case cutBaseURL = "cut_base_url"
        case cutWebURL = "cut_web_url"
        case cutWebUpdateDate = "cut_web_updatedate"
        case genre
        case url
        case pixivURL = "pixiv_url"
        case twitterURL = "twitter_url"
        case clipStudioURL = "clipstudio_url"
        case niconicoURL = "niconico_url"
        case tag
        case circleDescription = "description"
        case onlineStores = "onlinestore"
        case updateID = "updateId"
        case updateDate = "update_date"
    }

    public static func == (lhs: WebCatalogCircle, rhs: WebCatalogCircle) -> Bool {
        return lhs.webCatalogID == rhs.webCatalogID &&
        lhs.circlemsID == rhs.circlemsID
    }
}
