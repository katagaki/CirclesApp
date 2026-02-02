//
//  ComiketCircleExtendedInformation.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite

final class ComiketCircleExtendedInformation: SQLiteable {
    var eventNumber: Int
    var id: Int
    var webCatalogID: Int
    var twitterURL: URL?
    var pixivURL: URL?
    var circleMsPortalURL: URL?

    var circle: ComiketCircle?

    init(from row: Row) {
        let table = Table("ComiketCircleExtend")

        let colEventNumber = table[Expression<Int>("comiketNo")]
        let colID = table[Expression<Int>("id")]
        let colWebCatalogID = Expression<Int>("WCId")
        let colTwitterURL = Expression<String>("twitterURL")
        let colPixivURL = Expression<String>("pixivURL")
        let colCircleMsPortalURL = Expression<String>("CirclemsPortalURL")

        self.eventNumber = row[colEventNumber]
        self.id = row[colID]
        self.webCatalogID = row[colWebCatalogID]

        if let twitterURL = URL(string: row[colTwitterURL]) {
            self.twitterURL = twitterURL
        }

        if let pixivURL = URL(string: row[colPixivURL]) {
            self.pixivURL = pixivURL
        }

        if let circleMsPortalURL = URL(string: row[colCircleMsPortalURL]) {
            self.circleMsPortalURL = circleMsPortalURL
        }
    }

    func hasAccessibleURLs() -> Bool {
        return twitterURL != nil || pixivURL != nil || circleMsPortalURL != nil
    }
}
