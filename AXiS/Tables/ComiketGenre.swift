//
//  ComiketGenre.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

public final class ComiketGenre: SQLiteable, Identifiable, Hashable {
    public static func == (lhs: ComiketGenre, rhs: ComiketGenre) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    public var eventNumber: Int
    public var id: Int
    public var name: String
    public var code: Int
    public var day: Int

    public required init(from row: Row) {
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
