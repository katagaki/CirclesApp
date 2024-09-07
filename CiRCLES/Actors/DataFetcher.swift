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

    func blocks(inMap mapID: Int) -> [PersistentIdentifier] {
        do {
            let layoutsFetchDescriptor = FetchDescriptor<ComiketLayout>(
                predicate: #Predicate<ComiketLayout> {
                    $0.mapID == mapID
                }
            )
            let layouts: [ComiketLayout] = try modelContext.fetch(layoutsFetchDescriptor)
            let blocks: [Int] = layouts.map({ $0.blockID })
            let blocksFetchDescriptor = FetchDescriptor<ComiketBlock>(
                predicate: #Predicate<ComiketBlock> {
                    blocks.contains($0.id)
                }
            )
            return try modelContext.fetchIdentifiers(blocksFetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func layouts(inMap mapID: Int) -> [PersistentIdentifier] {
        do {
            let mapFetchDescriptor = FetchDescriptor<ComiketMap>(
                predicate: #Predicate<ComiketMap> {
                    $0.id == mapID
                }
            )
            if let map = try modelContext.fetch(mapFetchDescriptor).first,
               let layouts = map.layouts {
                return layouts.map({$0.persistentModelID})
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        return []
    }

    func circleWebCatalogIDs(inBlock blockID: Int, inSpace spaceNumber: Int, on dateID: Int) -> [Int] {
        let fetchDescriptor = FetchDescriptor<ComiketCircle>(
            predicate: #Predicate<ComiketCircle> {
                $0.blockID == blockID &&
                $0.spaceNumber == spaceNumber &&
                $0.day == dateID
            }
        )
        do {
            var circles = try modelContext.fetch(fetchDescriptor)
            circles.sort(by: {$0.spaceNumber < $1.spaceNumber})
            return circles
                .compactMap { $0.extendedInformation }
                .map { $0.webCatalogID }
        } catch {
            debugPrint(error.localizedDescription)
            return []
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

    func circles(withWebCatalogIDs webCatalogIDs: [Int]) -> [PersistentIdentifier] {
        do {
            var circleIdentifiers: [PersistentIdentifier] = []
            for webCatalogID in webCatalogIDs {
                let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                    predicate: #Predicate<ComiketCircle> {
                        $0.extendedInformation.flatMap({$0.webCatalogID}) == webCatalogID
                    }
                )
                let circleIdentifier = try modelContext.fetchIdentifiers(fetchDescriptor).first
                if let circleIdentifier {
                    circleIdentifiers.append(circleIdentifier)
                }
            }
            return circleIdentifiers
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(forFavorites favoriteItems: [UserFavorites.Response.FavoriteItem]) -> [PersistentIdentifier] {
        do {
            let webCatalogIDs = favoriteItems.map({$0.circle.webCatalogID})
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> {
                    $0.extendedInformation.flatMap {
                        webCatalogIDs.contains($0.webCatalogID)
                    } == true
                }
            )
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }
}
