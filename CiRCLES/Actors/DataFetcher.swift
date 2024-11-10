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

    // MARK: Fetching

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
            let blocks: [Int] = layouts.map({$0.blockID})
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

    func genre(_ genreID: Int) -> String? {
        let fetchDescriptor = FetchDescriptor<ComiketGenre>(
            predicate: #Predicate<ComiketGenre> {
                $0.id == genreID
            }
        )
        do {
            return (try modelContext.fetch(fetchDescriptor)).first?.name
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    func circleWebCatalogIDs(
        forMappings mappings: [LayoutCatalogMapping],
        on dateID: Int
    ) -> [LayoutCatalogMapping: [Int]] {
        do {
            var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
            let blockIDs = Set(mappings.map { $0.blockID })
            let spaceNumbers = Set(mappings.map { $0.spaceNumber })
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> { circle in
                    blockIDs.contains(circle.blockID) &&
                    spaceNumbers.contains(circle.spaceNumber) &&
                    circle.day == dateID
                },
                sortBy: [SortDescriptor(\.id, order: .forward)]
            )
            let circles = try modelContext.fetch(fetchDescriptor)
            let circleWebCatalogIDMapping = circles.reduce(
                into: [LayoutCatalogMapping: [Int]]()) { partialResult, circle in
                    if let extendedInformation = circle.extendedInformation {
                        let mapping = LayoutCatalogMapping(blockID: circle.blockID, spaceNumber: circle.spaceNumber)
                        partialResult[mapping, default: []].append(extendedInformation.webCatalogID)
                    }
                }
            for (blockIDAndSpaceNumber, webCatalogIDs) in circleWebCatalogIDMapping {
                if let originalMapping = mappings.first(where: {
                    $0.blockID == blockIDAndSpaceNumber.blockID &&
                    $0.spaceNumber == blockIDAndSpaceNumber.spaceNumber
                }) {
                    layoutWebCatalogIDMappings[originalMapping] = webCatalogIDs
                }
            }
            return layoutWebCatalogIDMappings
        } catch {
            debugPrint(error)
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

    func circles(inMap mapID: Int) -> [PersistentIdentifier] {
        do {
            let mappingFetchDescriptor = FetchDescriptor<ComiketMapping>(
                predicate: #Predicate<ComiketMapping> {
                    $0.mapID == mapID
                }
            )
            let mappings = try modelContext.fetch(mappingFetchDescriptor)
            let blockIDs = mappings.map({$0.blockID}).sorted()
            var circleIdentifiers: [PersistentIdentifier] = []
            for blockID in blockIDs {
                circleIdentifiers.append(contentsOf: circles(inBlock: blockID))
            }
            return circleIdentifiers
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }

    }

    func circles(inBlock blockID: Int) -> [PersistentIdentifier] {
        do {
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> {
                    $0.blockID == blockID
                }
            )
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(withGenre genreID: Int) -> [PersistentIdentifier] {
        do {
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> {
                    $0.genreID == genreID
                }
            )
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
