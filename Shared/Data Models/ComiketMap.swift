//
//  ComiketMap.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

final class ComiketMap: SQLiteable, Identifiable, Hashable {
    static func == (lhs: ComiketMap, rhs: ComiketMap) -> Bool {
        return lhs.id == rhs.id && lhs.eventNumber == rhs.eventNumber
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(eventNumber)
    }

    var eventNumber: Int
    var id: Int
    var name: String
    var filename: String
    var allFilename: String
    var configuration: MapConfiguration
    var hdConfiguration: MapConfiguration
    var rotation: Int

    var layouts: [ComiketLayout]?

    init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colName = Expression<String>("name")
        let colFilename = Expression<String>("filename")
        let colMapX = Expression<Int>("x")
        let colMapY = Expression<Int>("y")
        let colMapW = Expression<Int>("w")
        let colMapH = Expression<Int>("h")
        let colAllFilename = Expression<String>("allFilename")
        let colHdMapX = Expression<Int>("x2")
        let colHdMapY = Expression<Int>("y2")
        let colHdMapW = Expression<Int>("w2")
        let colHdMapH = Expression<Int>("h2")
        let colRotation = Expression<Int>("rotate")

        self.eventNumber = row[colEventNumber]
        self.id = row[colID]
        self.name = row[colName]

        self.filename = row[colFilename]
        self.allFilename = row[colAllFilename]

        self.configuration = MapConfiguration(
            size: Size(width: row[colMapW], height: row[colMapH]),
            origin: Point(x: row[colMapX], y: row[colMapY])
        )

        self.hdConfiguration = MapConfiguration(
            size: Size(width: row[colHdMapW], height: row[colHdMapH]),
            origin: Point(x: row[colHdMapX], y: row[colHdMapY])
        )

        self.rotation = row[colRotation]
    }
}
