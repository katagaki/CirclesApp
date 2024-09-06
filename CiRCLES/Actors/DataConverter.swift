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

    func save() {
        do {
            debugPrint("Saving data models via actor")
            try modelContext.save()
            debugPrint("Saved data models via actor")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    // MARK: Loading

    func loadAll(from database: Connection?) async {
        loadEvents(from: database)
        loadDates(from: database)
        loadMaps(from: database)
        loadAreas(from: database)
        loadBlocks(from: database)
        loadMapping(from: database)
        loadLayouts(from: database)
        loadGenres(from: database)
        loadCircles(from: database)
        save()
        debugPrint("SwiftData models loaded via actor")
    }

    func loadEvents(from database: Connection?) {
        loadTable("ComiketInfoWC", from: database, of: ComiketEvent.self)
    }

    func loadDates(from database: Connection?) {
        loadTable("ComiketDateWC", from: database, of: ComiketDate.self)
    }

    func loadMaps(from database: Connection?) {
        loadTable("ComiketMapWC", from: database, of: ComiketMap.self)
    }

    func loadAreas(from database: Connection?) {
        loadTable("ComiketAreaWC", from: database, of: ComiketArea.self)
    }

    func loadBlocks(from database: Connection?) {
        loadTable("ComiketBlockWC", from: database, of: ComiketBlock.self)
    }

    func loadMapping(from database: Connection?) {
        loadTable("ComiketMappingWC", from: database, of: ComiketMapping.self)
    }

    func loadGenres(from database: Connection?) {
        loadTable("ComiketGenreWC", from: database, of: ComiketGenre.self)
    }

    func loadLayouts(from database: Connection?) {
        if let database {
            do {
                debugPrint("Preparing map data for layouts")
                let mapsFetchDescriptor = FetchDescriptor<ComiketMap>()
                let maps = try modelContext.fetch(mapsFetchDescriptor)
                let mapMappings: [Int: ComiketMap] = maps.reduce(
                    into: [Int: ComiketMap]()
                ) { partialResult, map in
                    partialResult[map.id] = map
                }

                debugPrint("Selecting from ComiketLayoutWC via actor")
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

    func loadCircles(from database: Connection?) {
        if let database {
            do {
                debugPrint("Selecting from ComiketCircleWC and ComiketCircleExtend via actor")
                let circlesTable = Table("ComiketCircleWC")
                let circleExtendedInformationTable = Table("ComiketCircleExtend")
                let id = Expression<Int>("id")

                let joinedTable = circlesTable.join(
                    .leftOuter,
                    circleExtendedInformationTable,
                    on: circlesTable[id] == circleExtendedInformationTable[id]
                )

                debugPrint("Preparing block data for circles")
                let blocksFetchDescriptor = FetchDescriptor<ComiketBlock>()
                let blocks = try modelContext.fetch(blocksFetchDescriptor)
                let blockMappings: [Int: ComiketBlock] = blocks.reduce(
                    into: [Int: ComiketBlock]()
                ) { partialResult, block in
                    partialResult[block.id] = block
                }

                debugPrint("Preparing layout data for circles")
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

                debugPrint("Starting insert of circles")
                for row in rows {
                    let circle = ComiketCircle(from: row)
                    let extendedInformation = ComiketCircleExtendedInformation(from: row)
                    circle.extendedInformation = extendedInformation
                    modelContext.insert(circle)
                    circle.block = blockMappings[circle.blockID]
                    circle.layout = layoutMappings["\(circle.blockID),\(circle.spaceNumber)"]
                    debugPrint("Inserted circle \(circle.id) via actor")
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    func loadTable<T: SQLiteable & PersistentModel>(_ tableName: String, from database: Connection?, of type: T.Type) {
        if let database {
            do {
                debugPrint("Selecting from \(tableName) via actor")
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

    // MARK: Reading

    func event(for eventNumber: Int) -> PersistentIdentifier? {
        let fetchDescriptor = FetchDescriptor<ComiketEvent>(
            predicate: #Predicate<ComiketEvent> {
                $0.eventNumber == eventNumber
            }
        )
        do {
            return (try modelContext.fetchIdentifiers(fetchDescriptor)).first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    // MARK: Maintenance

    func deleteAllData() {
        debugPrint("Deleting all data via actor")
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
