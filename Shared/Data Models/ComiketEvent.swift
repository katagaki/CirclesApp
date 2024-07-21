//
//  ComiketEvent.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite
import SwiftData

@Model
final class ComiketEvent: SQLiteable {
    @Attribute(.unique) var eventNumber: Int
    var name: String
    var circleCutConfiguration: CircleCutConfiguration
    var mapConfiguration: MapConfiguration
    var hdMapConfiguration: MapConfiguration

    init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colName = Expression<String>("comiketName")
        let colCutSizeW = Expression<Int>("cutSizeW")
        let colCutSizeH = Expression<Int>("cutSizeH")
        let colCutOriginX = Expression<Int>("cutOriginX")
        let colCutOriginY = Expression<Int>("cutOriginY")
        let colCutOffsetX = Expression<Int>("cutOffsetX")
        let colCutOffsetY = Expression<Int>("cutOffsetY")
        let colMapSizeW = Expression<Int>("mapSizeW")
        let colMapSizeH = Expression<Int>("mapSizeH")
        let colMapOriginX = Expression<Int>("mapOriginX")
        let colMapOriginY = Expression<Int>("mapOriginY")
        let colHdMapSizeW = Expression<Int>("map2SizeW")
        let colHdMapSizeH = Expression<Int>("map2SizeH")
        let colHdMapOriginX = Expression<Int>("map2OriginX")
        let colHdMapOriginY = Expression<Int>("map2OriginY")

        self.eventNumber = row[colEventNumber]
        self.name = row[colName]

        self.circleCutConfiguration = CircleCutConfiguration(
            size: Size(width: row[colCutSizeW], height: row[colCutSizeH]),
            origin: Point(x: row[colCutOriginX], y: row[colCutOriginY]),
            offset: Point(x: row[colCutOffsetX], y: row[colCutOffsetY])
        )

        self.mapConfiguration = MapConfiguration(
            size: Size(width: row[colMapSizeW], height: row[colMapSizeH]),
            origin: Point(x: row[colMapOriginX], y: row[colMapOriginY])
        )

        self.hdMapConfiguration = MapConfiguration(
            size: Size(width: row[colHdMapSizeW], height: row[colHdMapSizeH]),
            origin: Point(x: row[colHdMapOriginX], y: row[colHdMapOriginY])
        )
    }
}
