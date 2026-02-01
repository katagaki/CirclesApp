//
//  DataFetcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SQLite

// swiftlint:disable type_body_length

actor DataFetcher {

    let database: Connection?

    init(database: Connection?) {
        self.database = database
    }

    // MARK: Fetching

    func dates(for eventNumber: Int) -> [Int: Date] {
        if let database {
            do {
                let table = Table("ComiketDateWC")
                let colEventNumber = Expression<Int>("comiketNo")
                let colID = Expression<Int>("id")
                let colYear = Expression<Int>("year")
                let colMonth = Expression<Int>("month")
                let colDay = Expression<Int>("day")
                let query = table.filter(colEventNumber == eventNumber).order(colID.asc)

                return try database.prepare(query).reduce(into: [Int: Date]()) { result, row in
                    let year = try row.get(colYear)
                    let month = try row.get(colMonth)
                    let day = try row.get(colDay)
                    let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
                    result[row[colID]] = date
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return [:]
    }

    func layoutMappings(inMap mapID: Int, useHighResolutionMaps: Bool) -> [LayoutCatalogMapping] {
        if let database {
            do {
                let table = Table("ComiketLayoutWC")
                let colMapID = Expression<Int>("mapId")
                let query = table.filter(colMapID == mapID)
                return try database.prepare(query).map { row in
                    let layout = ComiketLayout(from: row)
                    return LayoutCatalogMapping(
                        blockID: layout.blockID,
                        spaceNumber: layout.spaceNumber,
                        positionX: useHighResolutionMaps ? layout.hdPosition.x : layout.position.x,
                        positionY: useHighResolutionMaps ? layout.hdPosition.y : layout.position.y,
                        layoutType: layout.layout
                    )
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func genre(_ genreID: Int) -> String? {
        if let database {
            do {
                let table = Table("ComiketGenreWC")
                let colID = Expression<Int>("id")
                let colName = Expression<String>("name")
                let query = table.select(colName).filter(colID == genreID)
                return try database.pluck(query)?[colName]
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }

    func layoutCatalogMappingToWebCatalogIDs(
        forMappings mappings: [LayoutCatalogMapping],
        on dateID: Int
    ) -> [LayoutCatalogMapping: [Int]] {
        if let database {
            do {
                let circlesTable = Table("ComiketCircleWC")
                let extendedTable = Table("ComiketCircleExtend")
                let colID = Expression<Int>("id")
                let colBlockID = Expression<Int>("blockId")
                let colSpaceNumber = Expression<Int>("spaceNo")
                let colDay = Expression<Int>("day")
                let colWebCatalogID = Expression<Int>("WCId")

                let blockIDs = Set(mappings.map { $0.blockID })
                let spaceNumbers = Set(mappings.map { $0.spaceNumber })

                let query = circlesTable
                    .join(.leftOuter, extendedTable, on: circlesTable[colID] == extendedTable[colID])
                    .filter(blockIDs.contains(colBlockID) && spaceNumbers.contains(colSpaceNumber) && colDay == dateID)
                    .order(circlesTable[colID].asc)

                let mappingLookup = Dictionary(uniqueKeysWithValues: mappings.map {
                    ("\($0.blockID)-\($0.spaceNumber)", $0)
                })

                var result = [LayoutCatalogMapping: [Int]]()
                for row in try database.prepare(query) {
                    if let webCatalogID = try? row.get(colWebCatalogID) {
                        let blockID = row[colBlockID]
                        let spaceNumber = row[colSpaceNumber]
                        if let originalMapping = mappingLookup["\(blockID)-\(spaceNumber)"] {
                            result[originalMapping, default: []].append(webCatalogID)
                        }
                    }
                }
                return result
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return [:]
    }

    func circles(containing searchTerm: String) -> [Int] {
        if let database {
            do {
                let table = Table("ComiketCircleWC")
                let colID = Expression<Int>("id")
                let colCircleName = Expression<String>("circleName")
                let colCircleNameKana = Expression<String>("circleKana")
                let colPenName = Expression<String>("penName")

                let query = table.select(colID).filter(
                    colCircleName.like("%\(searchTerm)%") ||
                    colCircleNameKana.like("%\(searchTerm)%") ||
                    colPenName.like("%\(searchTerm)%")
                )
                return try database.prepare(query).map { $0[colID] }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(
        withGenre genreIDs: [Int]? = nil,
        inBlock blockIDs: [Int]? = nil,
        onDay day: Int? = nil
    ) -> [Int]? {
        if let database {
            do {
                let table = Table("ComiketCircleWC")
                let colID = Expression<Int>("id")
                let colGenreID = Expression<Int>("genreId")
                let colBlockID = Expression<Int>("blockId")
                let colDay = Expression<Int>("day")

                var query = table.select(colID)
                if let genreIDs, !genreIDs.isEmpty {
                    query = query.filter(genreIDs.contains(colGenreID))
                }
                if let blockIDs, !blockIDs.isEmpty {
                    query = query.filter(blockIDs.contains(colBlockID))
                }
                if let day {
                    query = query.filter(colDay == day)
                }

                if genreIDs == nil && blockIDs == nil && day == nil {
                    return nil
                }

                return try database.prepare(query).map { $0[colID] }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(
        inMap mapID: Int?,
        withGenre genreIDs: [Int]?,
        inBlock blockIDs: [Int]?,
        onDay dayID: Int?
    ) -> [Int] {
        if let database {
            do {
                let table = Table("ComiketCircleWC")
                let colID = Expression<Int>("id")
                let colGenreID = Expression<Int>("genreId")
                let colBlockID = Expression<Int>("blockId")
                let colDay = Expression<Int>("day")

                var query = table.select(colID)
                var hasFilter = false

                if let mapID {
                    let mappingTable = Table("ComiketMappingWC")
                    let colMapID = Expression<Int>("mapId")
                    let colMappingBlockID = Expression<Int>("blockId")

                    let mappingQuery = mappingTable.select(colMappingBlockID).filter(colMapID == mapID)
                    let blockIDs = Set(try database.prepare(mappingQuery).map { $0[colMappingBlockID] })
                    
                    if blockIDs.isEmpty {
                        return []
                    }

                    query = query.filter(blockIDs.contains(colBlockID))
                    hasFilter = true
                }

                if let genreIDs, !genreIDs.isEmpty {
                    query = query.filter(genreIDs.contains(colGenreID))
                    hasFilter = true
                }

                if let blockIDs, !blockIDs.isEmpty {
                    query = query.filter(blockIDs.contains(colBlockID))
                    hasFilter = true
                }

                if let dayID {
                    query = query.filter(colDay == dayID)
                    hasFilter = true
                }

                if hasFilter {
                    return try database.prepare(query).map { $0[colID] }
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(inMap mapID: Int) -> [Int] {
        if let database {
            do {
                let mappingTable = Table("ComiketMappingWC")
                let circlesTable = Table("ComiketCircleWC")
                let colMapID = Expression<Int>("mapId")
                let colBlockID = Expression<Int>("blockId")
                let colID = Expression<Int>("id")

                let mappingQuery = mappingTable.select(colBlockID).filter(colMapID == mapID)
                let blockIDs = Set(try database.prepare(mappingQuery).map { $0[colBlockID] })

                let circlesQuery = circlesTable.select(colID).filter(blockIDs.contains(colBlockID))
                return try database.prepare(circlesQuery).map { $0[colID] }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func genreIDs(inMap mapID: Int, onDay dayID: Int) -> [Int] {
        if let database {
            do {
                let mappingTable = Table("ComiketMappingWC")
                let circlesTable = Table("ComiketCircleWC")
                let colMapID = Expression<Int>("mapId")
                let colBlockID = Expression<Int>("blockId")
                let colDay = Expression<Int>("day")
                let colGenreID = Expression<Int>("genreId")

                let mappingQuery = mappingTable.select(colBlockID).filter(colMapID == mapID)
                let blockIDs = Set(try database.prepare(mappingQuery).map { $0[colBlockID] })

                let circlesQuery = circlesTable
                    .select(colGenreID)
                    .filter(blockIDs.contains(colBlockID) && colDay == dayID)
                return Array(Set(try database.prepare(circlesQuery).map { $0[colGenreID] }))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func blockIDs(inMap mapID: Int, onDay dayID: Int, withGenreIDs genreIDs: [Int]?) -> [Int] {
        if let database {
            do {
                let mappingTable = Table("ComiketMappingWC")
                let circlesTable = Table("ComiketCircleWC")
                let colMapID = Expression<Int>("mapId")
                let colBlockID = Expression<Int>("blockId")
                let colDay = Expression<Int>("day")
                let colGenreID = Expression<Int>("genreId")

                let mappingQuery = mappingTable.select(colBlockID).filter(colMapID == mapID)
                let blockIDs = Set(try database.prepare(mappingQuery).map { $0[colBlockID] })

                var circlesQuery = circlesTable
                    .select(colBlockID)
                    .filter(blockIDs.contains(colBlockID) && colDay == dayID)
                if let genreIDs, !genreIDs.isEmpty {
                    circlesQuery = circlesQuery.filter(genreIDs.contains(colGenreID))
                }
                return Array(Set(try database.prepare(circlesQuery).map { $0[colBlockID] }))
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(withWebCatalogIDs webCatalogIDs: [Int]) -> [Int] {
        if let database {
            do {
                let extendedTable = Table("ComiketCircleExtend")
                let colID = Expression<Int>("id")
                let colWebCatalogID = Expression<Int>("WCId")
                let query = extendedTable.select(colID).filter(webCatalogIDs.contains(colWebCatalogID))
                return try database.prepare(query).map { $0[colID] }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return []
    }

    func circles(forFavorites favoriteItems: [UserFavorites.Response.FavoriteItem]) -> [Int] {
        let webCatalogIDs = favoriteItems.map { $0.circle.webCatalogID }
        return circles(withWebCatalogIDs: webCatalogIDs)
    }

    func spaceNumberSuffixes(forWebCatalogIDs webCatalogIDs: [Int]) -> [Int: Int] {
        if let database {
            do {
                let circlesTable = Table("ComiketCircleWC")
                let extendedTable = Table("ComiketCircleExtend")
                let colID = Expression<Int>("id")
                let colWebCatalogID = Expression<Int>("WCId")
                let colSpaceNoSub = Expression<Int>("spaceNoSub")

                let query = circlesTable
                    .join(.inner, extendedTable, on: circlesTable[colID] == extendedTable[colID])
                    .filter(webCatalogIDs.contains(colWebCatalogID))

                return try database.prepare(query).reduce(into: [Int: Int]()) { result, row in
                    result[row[colWebCatalogID]] = row[colSpaceNoSub]
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        return webCatalogIDs.reduce(into: [:]) { result, webCatalogID in
            result[webCatalogID] = 0
        }
    }
}

// swiftlint:enable type_body_length
