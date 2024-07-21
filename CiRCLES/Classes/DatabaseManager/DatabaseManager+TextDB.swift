//
//  DatabaseManager+TextDB.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import SQLite

extension DatabaseManager {

    func loadEvents() {
        if let events = loadTable("ComiketInfoWC", of: ComiketEvent.self) as? [ComiketEvent] {
            self.events = events
        }
    }

    func loadDates() {
        if let eventDates = loadTable("ComiketDateWC", of: ComiketDate.self) as? [ComiketDate] {
            self.eventDates = eventDates
        }
    }

    func loadMaps() {
        if let eventMaps = loadTable("ComiketMapWC", of: ComiketMap.self) as? [ComiketMap] {
            self.eventMaps = eventMaps
        }
    }

    func loadAreas() {
        if let eventAreas = loadTable("ComiketAreaWC", of: ComiketArea.self) as? [ComiketArea] {
            self.eventAreas = eventAreas
        }
    }

    func loadBlocks() {
        if let eventBlocks = loadTable("ComiketBlockWC", of: ComiketBlock.self) as? [ComiketBlock] {
            self.eventBlocks = eventBlocks
        }
    }

    func loadGenres() {
        if let eventGenres = loadTable("ComiketGenreWC", of: ComiketGenre.self) as? [ComiketGenre] {
            self.eventGenres = eventGenres
        }
    }

    func loadLayouts() {
        if let eventLayouts = loadTable("ComiketLayoutWC", of: ComiketLayout.self) as? [ComiketLayout] {
            self.eventLayouts = eventLayouts
        }
    }

    func loadCircles() {
        if let eventCircles = loadTable("ComiketCircleWC", of: ComiketCircle.self) as? [ComiketCircle] {
            self.eventCircles = eventCircles
        }
    }

    func loadCircleExtendedInformtion() {
        if let eventCircleExtendedInformation = loadTable(
            "ComiketCircleExtend",
            of: ComiketCircleExtendedInformation.self
        ) as? [ComiketCircleExtendedInformation] {
            self.eventCircleExtendedInformation = eventCircleExtendedInformation
        }
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
