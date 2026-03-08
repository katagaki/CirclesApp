//
//  ComiketCircle.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite

public final class ComiketCircle: SQLiteable, Identifiable, Hashable {
    public static func == (lhs: ComiketCircle, rhs: ComiketCircle) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    public var eventNumber: Int
    public var id: Int

    public var pageNumber: Int
    public var cutIndex: Int
    public var day: Int
    public var blockID: Int
    public var spaceNumber: Int
    public var spaceNumberSuffix: Int
    public var genreID: Int
    public var circleName: String
    public var circleNameKana: String
    public var penName: String
    public var bookName: String
    public var url: URL?
    public var mailAddress: String
    public var supplementaryDescription: String
    public var memo: String
    public var updateID: Int
    public var updateData: String
    public var circleMsURL: URL?
    public var rss: String
    public var updateFlag: Int

    public var extendedInformation: ComiketCircleExtendedInformation?

    public var block: ComiketBlock?

    public var layout: ComiketLayout?

    public required init(from row: Row) {
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

    public func spaceName() -> String? {
        if let block {
            return "\(block.name)\(spaceNumberCombined())"
        } else {
            return nil
        }
    }

    public func spaceNumberCombined() -> String {
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
