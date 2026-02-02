//
//  ComiketGenre.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

final class ComiketGenre: SQLiteable, Identifiable, Hashable {
    static func == (lhs: ComiketGenre, rhs: ComiketGenre) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    var eventNumber: Int
    var id: Int
    var name: String
    var code: Int
    var day: Int

    init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colName = Expression<String>("name")
        let colCode = Expression<Int>("code")
        let colDay = Expression<Int>("day")

        self.eventNumber = row[colEventNumber]
        self.id = row[colID]
        self.name = row[colName]

        self.code = row[colCode]
        self.day = row[colDay]
    }
}
