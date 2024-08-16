//
//  DatabaseManager+TextDB.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

extension DatabaseManager {

    // MARK: Loading

    func loadEvents() async {
        if let events = loadTable("ComiketInfoWC", of: ComiketEvent.self) as? [ComiketEvent] {
            self.events = events
        }
    }

    func loadDates() async {
        if let eventDates = loadTable("ComiketDateWC", of: ComiketDate.self) as? [ComiketDate] {
            self.eventDates = eventDates
        }
    }

    func loadMaps() async {
        if let eventMaps = loadTable("ComiketMapWC", of: ComiketMap.self) as? [ComiketMap] {
            self.eventMaps = eventMaps
        }
    }

    func loadAreas() async {
        if let eventAreas = loadTable("ComiketAreaWC", of: ComiketArea.self) as? [ComiketArea] {
            self.eventAreas = eventAreas
        }
    }

    func loadBlocks() async {
        if let eventBlocks = loadTable("ComiketBlockWC", of: ComiketBlock.self) as? [ComiketBlock] {
            self.eventBlocks = eventBlocks
        }
    }

    func loadMapping() async {
        if let eventMapping = loadTable("ComiketMappingWC", of: ComiketMapping.self) as? [ComiketMapping] {
            self.eventMapping = eventMapping
        }
    }

    func loadGenres() async {
        if let eventGenres = loadTable("ComiketGenreWC", of: ComiketGenre.self) as? [ComiketGenre] {
            self.eventGenres = eventGenres
        }
    }

    func loadLayouts() async {
        if let eventLayouts = loadTable("ComiketLayoutWC", of: ComiketLayout.self) as? [ComiketLayout] {
            self.eventLayouts = eventLayouts
        }
    }

    func loadCircles(forcefully: Bool = false) async {
        if forcefully || self.eventCircles.count == 0 {
            if let eventCircles = loadTable("ComiketCircleWC", of: ComiketCircle.self) as? [ComiketCircle] {
                self.eventCircles = eventCircles
            }
        } else {
            debugPrint("Circles data loaded from cache")
        }
    }

    func loadCircleExtendedInformtion() async {
        if let eventCircleExtendedInformation = loadTable(
            "ComiketCircleExtend",
            of: ComiketCircleExtendedInformation.self
        ) as? [ComiketCircleExtendedInformation] {
            self.eventCircleExtendedInformation = eventCircleExtendedInformation
        }
    }

    // MARK: Fetching

    func circles(in block: ComiketBlock) -> [ComiketCircle] {
        return eventCircles.filter({
            $0.blockID == block.id
        })
    }

    func circles(in layout: ComiketLayout) -> [ComiketCircle] {
        return eventCircles.filter({
            $0.blockID == layout.blockID && $0.spaceNumber == layout.spaceNumber
        })
    }

    func circles(in layout: ComiketLayout, on date: Int) -> [ComiketCircle] {
        return circles(in: layout).filter({ $0.day == date })
    }

    func blocks(in map: ComiketMap) -> [ComiketBlock] {
        let mapLayouts = eventLayouts.filter({ $0.mapID == map.id })
        let mapBlockIDs = mapLayouts.map({ $0.blockID })
        return eventBlocks.filter({ mapBlockIDs.contains($0.id) }).sorted(by: { $0.id < $1.id })
    }

    func layouts(for map: ComiketMap) -> [ComiketLayout] {
        let currentMappings: [ComiketMapping] = eventMapping.filter({ $0.mapID == map.id })
        let currentBlockIDs: [Int] = currentMappings.map({ $0.blockID })
        return eventLayouts.filter({ currentBlockIDs.contains($0.blockID) })
    }

    func extendedCircleInformation(for circleID: Int) -> ComiketCircleExtendedInformation? {
        return self.eventCircleExtendedInformation.first(where: {
            $0.id == circleID
        })
    }

    // MARK: Shared Functions

    func loadTable<T: SQLiteable>(_ tableName: String, of type: T.Type) -> [SQLiteable]? {
        if let textDatabase {
            do {
                debugPrint("Selecting from \(tableName)")
                let table = Table("\(tableName)")
                var loadedRows: [SQLiteable] = []
                for row in try textDatabase.prepare(table) {
                    loadedRows.append(T(from: row))
                }
                return loadedRows
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

}
