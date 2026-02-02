//
//  ComiketBlock.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

final class ComiketBlock: SQLiteable, Identifiable, Hashable {
    static func == (lhs: ComiketBlock, rhs: ComiketBlock) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    var eventNumber: Int
    var id: Int
    var name: String
    var areaID: Int

    var circles: [ComiketCircle]?

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
