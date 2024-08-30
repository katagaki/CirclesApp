//
//  WebCatalogCircle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/04.
//

struct WebCatalogCircle: Codable {
    let webCatalogID: Int
    let name: String
    let nameKana: String
    let circlemsID: Int
    let cutURL: String
    let cutBaseURL: String
    let cutWebURL: String
    let cutWebUpdateDate: String
    let genre: Int
    let url: String
    let pixivURL: String
    let twitterURL: String
    let clipStudioURL: String
    let niconicoURL: String
    let tag: String
    let description: String
    let onlineStores: [OnlineStore]
    let updateID: Int
    let updateDate: String

    struct OnlineStore: Codable {
        let name: String
        let link: String
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
        case description
        case onlineStores = "onlinestore"
        case updateID = "updateId"
        case updateDate = "update_date"
    }
}
