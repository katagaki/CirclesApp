//
//  ComiketMapping.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/08/15.
//

import SQLite
import SwiftData

@Model
final class ComiketMapping: SQLiteable {
    var eventNumber: Int
    var day: Int
    var mapID: Int
    var areaID: Int
    var floorID: Int
    var blockID: Int

    init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colDay = Expression<Int>("day")
        let colMapID = Expression<Int>("mapId")
        let colAreaID = Expression<Int>("areaId")
        let colFloorID = Expression<Int>("floorId")
        let colBlockID = Expression<Int>("blockId")

        self.eventNumber = row[colEventNumber]
        self.day = row[colDay]
        self.mapID = row[colMapID]
        self.areaID = row[colAreaID]
        self.floorID = row[colFloorID]
        self.blockID = row[colBlockID]
    }
}
