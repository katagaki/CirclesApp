//
//  DataFetcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SwiftData

@ModelActor
actor DataFetcher {

    func dates(for eventNumber: Int) -> [Int: Date] {
        let fetchDescriptor = FetchDescriptor<ComiketDate>(
            predicate: #Predicate<ComiketDate> {
                $0.eventNumber == eventNumber
            },
            sortBy: [SortDescriptor(\.id, order: .forward)]
        )
        do {
            let dates = try modelContext.fetch(fetchDescriptor)
            var dayAndDate: [Int: Date] = [:]
            for date in dates {
                dayAndDate[date.id] = date.date
            }
            return dayAndDate
        } catch {
            debugPrint(error.localizedDescription)
            return [:]
        }
    }

    func circles(containing searchTerm: String) -> [PersistentIdentifier] {
        let searchTermLowercased = searchTerm.lowercased()
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.circleName.localizedStandardContains(searchTermLowercased) ||
                $0.circleNameKana.localizedStandardContains(searchTermLowercased) ||
                $0.penName.localizedStandardContains(searchTermLowercased)
            }
        )
        do {
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(inBlock blockID: Int, inSpace spaceNumber: Int) -> [PersistentIdentifier] {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID && $0.spaceNumber == spaceNumber
            }
        )
        do {
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(inBlock blockID: Int) -> [PersistentIdentifier] {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID
            }
        )
        do {
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(withGenre genreID: Int) -> [PersistentIdentifier] {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.genreID == genreID
            }
        )
        do {
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

}
