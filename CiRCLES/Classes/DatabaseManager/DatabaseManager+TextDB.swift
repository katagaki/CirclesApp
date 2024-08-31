//
//  DatabaseManager+TextDB.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import SwiftData

extension DatabaseManager {

    // MARK: Loading

    func loadEvents() {
        downloadProgressTextKey = "Shared.LoadingText.Events"
        if let events = loadTable("ComiketInfoWC", of: ComiketEvent.self) as? [ComiketEvent] {
            for event in events {
                modelContext.insert(event)
            }
        }
    }

    func loadDates() {
        downloadProgressTextKey = "Shared.LoadingText.Events"
        if let eventDates = loadTable("ComiketDateWC", of: ComiketDate.self) as? [ComiketDate] {
            for date in eventDates {
                modelContext.insert(date)
            }
        }
    }

    func loadMaps() {
        downloadProgressTextKey = "Shared.LoadingText.Maps"
        if let eventMaps = loadTable("ComiketMapWC", of: ComiketMap.self) as? [ComiketMap] {
            for map in eventMaps {
                modelContext.insert(map)
            }
        }
    }

    func loadAreas() {
        downloadProgressTextKey = "Shared.LoadingText.Maps"
        if let eventAreas = loadTable("ComiketAreaWC", of: ComiketArea.self) as? [ComiketArea] {
            for area in eventAreas {
                modelContext.insert(area)
            }
        }
    }

    func loadBlocks() {
        downloadProgressTextKey = "Shared.LoadingText.Maps"
        if let eventBlocks = loadTable("ComiketBlockWC", of: ComiketBlock.self) as? [ComiketBlock] {
            for block in eventBlocks {
                modelContext.insert(block)
            }
        }
    }

    func loadMapping() {
        downloadProgressTextKey = "Shared.LoadingText.Maps"
        if let eventMapping = loadTable("ComiketMappingWC", of: ComiketMapping.self) as? [ComiketMapping] {
            for mapping in eventMapping {
                modelContext.insert(mapping)
            }
        }
    }

    func loadGenres() {
        downloadProgressTextKey = "Shared.LoadingText.Genres"
        if let eventGenres = loadTable("ComiketGenreWC", of: ComiketGenre.self) as? [ComiketGenre] {
            for genre in eventGenres {
                modelContext.insert(genre)
            }
        }
    }

    func loadLayouts() {
        downloadProgressTextKey = "Shared.LoadingText.Maps"
        if let eventLayouts = loadTable("ComiketLayoutWC", of: ComiketLayout.self) as? [ComiketLayout] {
            for layout in eventLayouts {
                modelContext.insert(layout)
            }
        }
    }

    func loadCircles() {
        downloadProgressTextKey = "Shared.LoadingText.Circles"
        let circlesTableWithExtendedInformation: [Row] = joinTable(
            from: "ComiketCircleExtend",
            into: "ComiketCircleWC",
            on: "id"
        )
        var eventCircles: [ComiketCircle] = []
        for row in circlesTableWithExtendedInformation {
            let circle: ComiketCircle = ComiketCircle(from: row)
            let extendedInformation: ComiketCircleExtendedInformation = ComiketCircleExtendedInformation(from: row)
            circle.extendedInformation = extendedInformation
            eventCircles.append(circle)
        }
        for circle in eventCircles {
            modelContext.insert(circle)
        }
    }

    // MARK: Fetching

    func event(for eventNumber: Int) -> ComiketEvent? {
        let fetchDescriptor = FetchDescriptor<ComiketEvent>(
            predicate: #Predicate<ComiketEvent> {
                $0.eventNumber == eventNumber
            }
        )
        do {
            return (try modelContext.fetch(fetchDescriptor)).first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    func dates(for eventNumber: Int) -> [ComiketDate] {
        let fetchDescriptor = FetchDescriptor<ComiketDate>(
            predicate: #Predicate<ComiketDate> {
                $0.eventNumber == eventNumber
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func block(_ id: Int) -> ComiketBlock? {
        let fetchDescriptor = FetchDescriptor<ComiketBlock>(
            predicate: #Predicate<ComiketBlock> {
                $0.id == id
            }
        )
        do {
            return (try modelContext.fetch(fetchDescriptor)).first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    func blocks(in map: ComiketMap) -> [ComiketBlock] {
        let mapLayouts = layouts(for: map)
        let mapBlockIDs = mapLayouts.map({ $0.blockID })
        let fetchDescriptor = FetchDescriptor<ComiketBlock>(
            predicate: #Predicate<ComiketBlock> {
                mapBlockIDs.contains($0.id)
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func layouts(for map: ComiketMap) -> [ComiketLayout] {
        let mapID = map.id
        let fetchDescriptor = FetchDescriptor<ComiketLayout>(
            predicate: #Predicate<ComiketLayout> {
                $0.mapID == mapID
            },
            sortBy: [SortDescriptor(\.mapID, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circle(for webCatalogID: Int) -> ComiketCircle? {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.extendedInformation?.webCatalogID == webCatalogID
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return (try modelContext.fetch(fetchDescriptor)).first
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    func circles(containing searchTerm: String) -> [ComiketCircle] {
        let orderedSame = ComparisonResult.orderedSame
        let searchTermLowercased = searchTerm.lowercased()
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.circleName.caseInsensitiveCompare(searchTermLowercased) == orderedSame ||
                $0.circleNameKana.caseInsensitiveCompare(searchTermLowercased) == orderedSame ||
                $0.penName.caseInsensitiveCompare(searchTermLowercased) == orderedSame
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(in block: ComiketBlock) -> [ComiketCircle] {
        let blockID = block.id
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(with genre: ComiketGenre) -> [ComiketCircle] {
        let genreID = genre.id
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.genreID == genreID
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(on date: Int) -> [ComiketCircle] {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.day == date
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(in layout: ComiketLayout) -> [ComiketCircle] {
        let blockID = layout.blockID
        let spaceNumber = layout.spaceNumber
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID && $0.spaceNumber == spaceNumber
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(in layout: ComiketLayout, on date: Int) -> [ComiketCircle] {
        return circles(in: layout).filter({ $0.day == date })
    }

    // MARK: Shared Functions

    func loadTable<T: SQLiteable & PersistentModel>(_ tableName: String, of type: T.Type) -> [SQLiteable]? {
        if let textDatabase {
            do {
                debugPrint("Selecting from \(tableName)")
                let table = Table("\(tableName)")
                var loadedRows: [SQLiteable] = []
                for row in try textDatabase.prepare(table) {
                    let swiftDataObjectFromTableRow = T(from: row)
                    modelContext.insert(swiftDataObjectFromTableRow)
                    loadedRows.append(swiftDataObjectFromTableRow)
                }
                return loadedRows
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func joinTable(from rhsTableName: String, into lhsTableName: String, on columnName: String) -> [Row] {
        if let textDatabase {
            do {
                debugPrint("Joining into \(lhsTableName) from \(rhsTableName) on \(columnName)")
                let lhsTable = Table("\(lhsTableName)")
                let rhsTable = Table("\(rhsTableName)")
                // TODO: Allow Int and String expressions for this
                let columnToJoin = Expression<Int>(columnName)

                let joinedTable = lhsTable.join(
                    .leftOuter,
                    rhsTable,
                    on: lhsTable[columnToJoin] == rhsTable[columnToJoin]
                )

                var rows: [Row] = []
                for row in try textDatabase.prepare(joinedTable) {
                    rows.append(row)
                }
                return rows
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }
}
