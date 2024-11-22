//
//  CirclesFavorite.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/11/22.
//

import Foundation
import SwiftData

@Model
final class CirclesFavorite {
    var webCatalogID: Int
    var circle: Circle
    var favorite: Favorite

    init(webCatalogID: Int, favoriteItem: UserFavorites.Response.FavoriteItem) {
        self.webCatalogID = webCatalogID
        self.circle = Circle(
            webCatalogID: favoriteItem.circle.webCatalogID,
            name: favoriteItem.circle.name,
            nameKana: favoriteItem.circle.nameKana,
            circlemsID: favoriteItem.circle.circlemsID,
            cutURL: favoriteItem.circle.cutURL,
            cutBaseURL: favoriteItem.circle.cutBaseURL,
            cutWebURL: favoriteItem.circle.cutWebURL,
            cutWebUpdateDate: favoriteItem.circle.cutWebUpdateDate,
            genre: favoriteItem.circle.genre,
            url: favoriteItem.circle.url,
            pixivURL: favoriteItem.circle.pixivURL,
            twitterURL: favoriteItem.circle.twitterURL,
            clipStudioURL: favoriteItem.circle.clipStudioURL,
            niconicoURL: favoriteItem.circle.niconicoURL,
            tag: favoriteItem.circle.tag,
            circleDescription: favoriteItem.circle.circleDescription,
            onlineStores: favoriteItem.circle.onlineStores,
            updateID: favoriteItem.circle.updateID,
            updateDate: favoriteItem.circle.updateDate
        )
        self.favorite = Favorite(
            webCatalogID: favoriteItem.favorite.webCatalogID,
            circleName: favoriteItem.favorite.circleName,
            color: favoriteItem.favorite.color,
            memo: favoriteItem.favorite.memo,
            free: favoriteItem.favorite.free,
            updateDate: favoriteItem.favorite.updateDate
        )
    }

    func favoriteItem() -> UserFavorites.Response.FavoriteItem {
        UserFavorites.Response.FavoriteItem(
            circle: WebCatalogCircle(
                webCatalogID: circle.webCatalogID,
                name: circle.name,
                nameKana: circle.nameKana,
                circlemsID: circle.circlemsID,
                cutURL: circle.cutURL,
                cutBaseURL: circle.cutBaseURL,
                cutWebURL: circle.cutWebURL,
                cutWebUpdateDate: circle.cutWebUpdateDate,
                genre: circle.genre,
                url: circle.url,
                pixivURL: circle.pixivURL,
                twitterURL: circle.twitterURL,
                clipStudioURL: circle.clipStudioURL,
                niconicoURL: circle.niconicoURL,
                tag: circle.tag,
                circleDescription: circle.circleDescription,
                onlineStores: circle.onlineStores,
                updateID: circle.updateID,
                updateDate: circle.updateDate
            ),
            favorite: WebCatalogFavorite(
                webCatalogID: favorite.webCatalogID,
                circleName: favorite.circleName,
                color: favorite.color,
                memo: favorite.memo,
                free: favorite.free,
                updateDate: favorite.updateDate
            )
        )
    }

    // Copied structs because SwiftData poops out on CodingKeys

    struct Circle: Codable {
        let webCatalogID: Int
        let name: String
        let nameKana: String
        let circlemsID: String
        let cutURL: String
        let cutBaseURL: String
        let cutWebURL: String
        let cutWebUpdateDate: String
        let genre: String
        let url: String
        let pixivURL: String
        let twitterURL: String
        let clipStudioURL: String
        let niconicoURL: String
        let tag: String
        let circleDescription: String
        let onlineStores: [WebCatalogCircle.OnlineStore]
        let updateID: String
        let updateDate: String
    }

    struct Favorite: Codable {
        let webCatalogID: Int
        let circleName: String
        let color: WebCatalogColor
        let memo: String?
        let free: String?
        let updateDate: String
    }
}
