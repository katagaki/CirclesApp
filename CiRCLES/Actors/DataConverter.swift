//
//  DataConverter.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SQLite
import SwiftData

@ModelActor
actor DataConverter {

    // MARK: Loading

    func loadAll(from database: Connection?) async {
        loadEvents(from: database)
        loadMaps(from: database)
        loadLayouts(from: database)
        loadGenres(from: database)
        loadCircles(from: database)
        save()
    }

    func loadEvents(from database: Connection?) {
        loadTable("ComiketInfoWC", from: database, of: ComiketEvent.self)
        loadTable("ComiketDateWC", from: database, of: ComiketDate.self)
    }

    func loadMaps(from database: Connection?) {
        loadTable("ComiketMapWC", from: database, of: ComiketMap.self)
        loadTable("ComiketAreaWC", from: database, of: ComiketArea.self)
        loadTable("ComiketBlockWC", from: database, of: ComiketBlock.self)
        loadTable("ComiketMappingWC", from: database, of: ComiketMapping.self)
    }

    func loadLayouts(from database: Connection?) {
        if let database {
            do {
                let mapsFetchDescriptor = FetchDescriptor<ComiketMap>()
                let maps = try modelContext.fetch(mapsFetchDescriptor)
                let mapMappings: [Int: ComiketMap] = maps.reduce(
                    into: [Int: ComiketMap]()
                ) { partialResult, map in
                    partialResult[map.id] = map
                }

                let table = Table("ComiketLayoutWC")
                for row in try database.prepare(table) {
                    let layout = ComiketLayout(from: row)
                    modelContext.insert(layout)
                    layout.map = mapMappings[layout.mapID]
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadGenres(from database: Connection?) {
        loadTable("ComiketGenreWC", from: database, of: ComiketGenre.self)
    }

    func loadCircles(from database: Connection?) {
        if let database {
            do {
                let circlesTable = Table("ComiketCircleWC")
                let circleExtendedInformationTable = Table("ComiketCircleExtend")
                let id = Expression<Int>("id")

                let joinedTable = circlesTable.join(
                    .leftOuter,
                    circleExtendedInformationTable,
                    on: circlesTable[id] == circleExtendedInformationTable[id]
                )

                let blocksFetchDescriptor = FetchDescriptor<ComiketBlock>()
                let blocks = try modelContext.fetch(blocksFetchDescriptor)
                let blockMappings: [Int: ComiketBlock] = blocks.reduce(
                    into: [Int: ComiketBlock]()
                ) { partialResult, block in
                    partialResult[block.id] = block
                }

                let layoutsFetchDescriptor = FetchDescriptor<ComiketLayout>()
                let layouts = try modelContext.fetch(layoutsFetchDescriptor)
                let layoutMappings: [String: ComiketLayout] = layouts.reduce(
                    into: [String: ComiketLayout]()
                ) { partialResult, layout in
                    partialResult["\(layout.blockID),\(layout.spaceNumber)"] = layout
                }
                var rows: [Row] = []
                for row in try database.prepare(joinedTable) {
                    rows.append(row)
                }

                for row in rows {
                    let circle = ComiketCircle(from: row)
                    let extendedInformation = ComiketCircleExtendedInformation(from: row)
                    circle.extendedInformation = extendedInformation
                    modelContext.insert(circle)
                    circle.block = blockMappings[circle.blockID]
                    circle.layout = layoutMappings["\(circle.blockID),\(circle.spaceNumber)"]
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadTable<T: SQLiteable & PersistentModel>(_ tableName: String, from database: Connection?, of type: T.Type) {
        if let database {
            do {
                let table = Table("\(tableName)")
                for row in try database.prepare(table) {
                    let swiftDataObjectFromTableRow = T(from: row)
                    modelContext.insert(swiftDataObjectFromTableRow)
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    // MARK: Maintenance

    func save() {
        do {
            try modelContext.save()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    func enableAutoSave() {
        modelContext.autosaveEnabled = true
    }

    func disableAutoSave() {
        modelContext.autosaveEnabled = false
    }

    func deleteAll() {
        do {
            try modelContext.delete(model: ComiketEvent.self)
            try modelContext.delete(model: ComiketDate.self)
            try modelContext.delete(model: ComiketMap.self)
            try modelContext.delete(model: ComiketArea.self)
            try modelContext.delete(model: ComiketBlock.self)
            try modelContext.delete(model: ComiketMapping.self)
            try modelContext.delete(model: ComiketGenre.self)
            try modelContext.delete(model: ComiketLayout.self)
            try modelContext.delete(model: ComiketCircleExtendedInformation.self)
            try modelContext.delete(model: ComiketCircle.self)
            try modelContext.save()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
