//
//  ComiketBlock.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite
import SwiftData

@Model
final class ComiketBlock: SQLiteable {
    var eventNumber: Int
    var id: Int
    var name: String
    var areaID: Int

    init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colName = Expression<String>("name")
        let colAreaID = Expression<Int>("areaId")

        self.eventNumber = row[colEventNumber]
        self.id = row[colID]
        self.name = row[colName]
        self.areaID = row[colAreaID]
    }
}
