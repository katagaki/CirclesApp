//
//  DatabaseManager+Data.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/21.
//

import Foundation
import SQLite
import SwiftData

extension DatabaseManager {

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
        let searchTermLowercased = searchTerm.lowercased()
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.circleName.localizedStandardContains(searchTermLowercased) ||
                $0.circleNameKana.localizedStandardContains(searchTermLowercased) ||
                $0.penName.localizedStandardContains(searchTermLowercased)
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
        let blockID = layout.blockID
        let spaceNumber = layout.spaceNumber
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID && $0.spaceNumber == spaceNumber && $0.day == date
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
}
