//
//  ComiketArea.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite
import SwiftData

@Model
final class ComiketArea: SQLiteable {
    var eventNumber: Int
    var id: Int
    var name: String
    var simpleName: String
    var mapID: Int
    var mapConfiguration: MapConfiguration
    var allFilename: String
    var hdMapConfiguration: MapConfiguration

    init(from row: Row) {
        let colNumber = Expression<Int>("comiketNo")
        let colID = Expression<Int>("id")
        let colName = Expression<String>("name")
        let colSimpleName = Expression<String>("simpleName")
        let colMapID = Expression<Int>("mapId")
        let colMapX = Expression<Int>("x")
        let colMapY = Expression<Int>("y")
        let colMapW = Expression<Int>("w")
        let colMapH = Expression<Int>("h")
        let colAllFilename = Expression<String>("allFilename")
        let colHdMapX = Expression<Int>("x2")
        let colHdMapY = Expression<Int>("y2")
        let colHdMapW = Expression<Int>("w2")
        let colHdMapH = Expression<Int>("h2")

        self.eventNumber = row[colNumber]
        self.id = row[colID]
        self.name = row[colName]
        self.simpleName = row[colSimpleName]
        self.mapID = row[colMapID]

        self.allFilename = row[colAllFilename]

        self.mapConfiguration = MapConfiguration(
            size: Size(width: row[colMapW], height: row[colMapH]),
            origin: Point(x: row[colMapX], y: row[colMapY])
        )

        self.hdMapConfiguration = MapConfiguration(
            size: Size(width: row[colHdMapW], height: row[colHdMapH]),
            origin: Point(x: row[colHdMapX], y: row[colHdMapY])
        )
    }
}
