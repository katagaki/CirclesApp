//
//  ComiketLayout.swift
//  AXiS
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

public final class ComiketLayout: SQLiteable {
    public var eventNumber: Int
    public var blockID: Int
    public var spaceNumber: Int
    public var position: Point
    public var hdPosition: Point
    public var layout: LayoutType
    public var mapID: Int
    public var hallID: Int

    public var map: ComiketMap?
    public var circles: [ComiketCircle]?

    public var mergedID: String {
        return String(blockID) + "|" + String(spaceNumber)
    }

    public required init(from row: Row) {
        let colEventNumber = Expression<Int>("comiketNo")
        let colBlockID = Expression<Int>("blockId")
        let colSpaceNumber = Expression<Int>("spaceNo")
        let colPositionX = Expression<Int>("xpos")
        let colPositionY = Expression<Int>("ypos")
        let colHdPositionX = Expression<Int>("xpos2")
        let colHdPositionY = Expression<Int>("ypos2")
        let colLayout = Expression<Int>("layout")
        let colMapID = Expression<Int>("mapId")
        let colHallID = Expression<Int>("hallId")

        self.eventNumber = row[colEventNumber]
        self.blockID = row[colBlockID]

        self.spaceNumber = row[colSpaceNumber]

        self.position = Point(x: row[colPositionX], y: row[colPositionY])
        self.hdPosition = Point(x: row[colHdPositionX], y: row[colHdPositionY])

        self.layout = LayoutType(rawValue: row[colLayout]) ?? .unknown
        self.mapID = row[colMapID]
        self.hallID = row[colHallID]
    }

    public enum LayoutType: Int, Codable, Sendable {
        case aOnLeft = 1
        case aOnBottom = 2
        case aOnRight = 3
        case aOnTop = 4
        case unknown
    }
}
