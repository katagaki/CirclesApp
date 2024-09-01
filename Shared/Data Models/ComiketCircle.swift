//
//  ComiketCircle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import SwiftData

@Model
final class ComiketCircle: SQLiteable {
    var eventNumber: Int
    @Attribute(.unique) var id: Int
    var pageNumber: Int
    var cutIndex: Int
    var day: Int
    var blockID: Int
    var spaceNumber: Int
    var spaceNumberSuffix: Int
    var genreID: Int
    var circleName: String
    var circleNameKana: String
    var penName: String
    var bookName: String
    var url: URL?
    var mailAddress: String
    var supplementaryDescription: String
    var memo: String
    var updateID: Int
    var updateData: String
    var circleMsURL: URL?
    var rss: String
    var updateFlag: Int

    @Relationship(.unique, deleteRule: .cascade, inverse: \ComiketCircleExtendedInformation.circle)
    var extendedInformation: ComiketCircleExtendedInformation?

    init(from row: Row) {
        let table = Table("ComiketCircleWC")

        let colEventNumber = table[Expression<Int>("comiketNo")]
        let colID = table[Expression<Int>("id")]
        let colPageNumber = Expression<Int>("pageNo")
        let colCutIndex = Expression<Int>("cutIndex")
        let colDay = Expression<Int>("day")
        let colBlockID = Expression<Int>("blockId")
        let colSpaceNumber = Expression<Int>("spaceNo")
        let colSpaceNumberSuffix = Expression<Int>("spaceNoSub")
        let colGenreID = Expression<Int>("genreId")
        let colCircleName = Expression<String>("circleName")
        let colCircleNameKana = Expression<String>("circleKana")
        let colPenName = Expression<String>("penName")
        let colBookName = Expression<String>("bookName")
        let colURL = Expression<String>("url")
        let colMailAddress = Expression<String>("mailAddr")
        let colSupplementaryDescription = Expression<String>("description")
        let colMemo = Expression<String>("memo")
        let colUpdateID = Expression<Int>("updateId")
        let colUpdateData = Expression<String>("updateData")
        let colCircleMsURL = Expression<String>("circlems")
        let colRSS = Expression<String>("rss")
        let colUpdateFlag = Expression<Int>("updateFlag")

        self.eventNumber = row[colEventNumber]
        self.id = row[colID]
        self.pageNumber = row[colPageNumber]
        self.cutIndex = row[colCutIndex]
        self.day = row[colDay]
        self.blockID = row[colBlockID]
        self.spaceNumber = row[colSpaceNumber]
        self.spaceNumberSuffix = row[colSpaceNumberSuffix]
        self.genreID = row[colGenreID]
        self.circleName = row[colCircleName]
        self.circleNameKana = row[colCircleNameKana]
        self.penName = row[colPenName]
        self.bookName = row[colBookName]

        if let url = URL(string: row[colURL]) {
            self.url = url
        }

        self.mailAddress = row[colMailAddress]
        self.supplementaryDescription = row[colSupplementaryDescription]
        self.memo = row[colMemo]
        self.updateID = row[colUpdateID]
        self.updateData = row[colUpdateData]

        if let circleMsURL = URL(string: row[colCircleMsURL]) {
            self.circleMsURL = circleMsURL
        }

        self.rss = row[colRSS]
        self.updateFlag = row[colUpdateFlag]
    }

    func spaceNumberCombined() -> String {
        var combinedSpaceNumber = String(format: "%02d", spaceNumber)
        switch spaceNumberSuffix {
        case 0: combinedSpaceNumber += "a"
        case 1: combinedSpaceNumber += "b"
        case 2: combinedSpaceNumber += "c"
        default: break
        }
        return combinedSpaceNumber
    }
}
