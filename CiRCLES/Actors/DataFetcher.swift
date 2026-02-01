//
//  DataFetcher.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/01.
//

import Foundation
import SwiftData

// swiftlint:disable type_body_length
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
            return dates.reduce(into: [Int: Date]()) { result, date in
                result[date.id] = date.date
            }
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
            let layouts = try modelContext.fetch(layoutsFetchDescriptor)
            let blockIDs = Set(layouts.map { $0.blockID })
            let blocksFetchDescriptor = FetchDescriptor<ComiketBlock>(
                predicate: #Predicate<ComiketBlock> {
                    blockIDs.contains($0.id)
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
            guard let map = try modelContext.fetch(mapFetchDescriptor).first,
                  let layouts = map.layouts else {
                return []
            }
            return layouts.map { $0.persistentModelID }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func layoutMappings(inMap mapID: Int, useHighResolutionMaps: Bool) -> [LayoutCatalogMapping] {
        do {
            let mapFetchDescriptor = FetchDescriptor<ComiketMap>(
                predicate: #Predicate<ComiketMap> {
                    $0.id == mapID
                }
            )
            if let map = try modelContext.fetch(mapFetchDescriptor).first,
               let layouts = map.layouts {
                return layouts.map {
                    LayoutCatalogMapping(
                        blockID: $0.blockID,
                        spaceNumber: $0.spaceNumber,
                        positionX: useHighResolutionMaps ? $0.hdPosition.x : $0.position.x,
                        positionY: useHighResolutionMaps ? $0.hdPosition.y : $0.position.y,
                        layoutType: $0.layout
                    )
                }
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
            return try modelContext.fetch(fetchDescriptor).first?.name
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    func layoutCatalogMappingToWebCatalogIDs(
        forMappings mappings: [LayoutCatalogMapping],
        on dateID: Int
    ) -> [LayoutCatalogMapping: [Int]] {
        do {
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

            let mappingLookup = Dictionary(uniqueKeysWithValues: mappings.map {
                ("\($0.blockID)-\($0.spaceNumber)", $0)
            })

            return circles.reduce(into: [LayoutCatalogMapping: [Int]]()) { result, circle in
                guard let extendedInformation = circle.extendedInformation,
                      let originalMapping = mappingLookup["\(circle.blockID)-\(circle.spaceNumber)"] else {
                    return
                }
                result[originalMapping, default: []].append(extendedInformation.webCatalogID)
            }
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

    func circles(
        withGenre genreIDs: [Int]? = nil,
        inBlock blockIDs: [Int]? = nil,
        onDay day: Int? = nil
    ) -> [PersistentIdentifier]? {
        do {
            var predicates: [Predicate<ComiketCircle>] = []
            if let genreIDs, !genreIDs.isEmpty {
                predicates.append(
                    #Predicate<ComiketCircle> {
                        genreIDs.contains($0.genreID)
                    }
                )
            }
            if let blockIDs, !blockIDs.isEmpty {
                predicates.append(
                    #Predicate<ComiketCircle> {
                        blockIDs.contains($0.blockID)
                    }
                )
            }
            if let day {
                predicates.append(
                    #Predicate<ComiketCircle> {
                        $0.day == day
                    }
                )
            }
            if predicates.isEmpty {
                return nil
            }
            let combinedPredicate = predicates.reduce(predicates[0]) { combined, next in
                #Predicate<ComiketCircle> {
                    combined.evaluate($0) && next.evaluate($0)
                }
            }
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: combinedPredicate
            )
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
            let blockIDs = Set(mappings.map { $0.blockID })
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> {
                    blockIDs.contains($0.blockID)
                }
            )
            return try modelContext.fetchIdentifiers(fetchDescriptor)
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func genreIDs(inMap mapID: Int, onDay dayID: Int) -> [Int] {
        do {
            let mappingFetchDescriptor = FetchDescriptor<ComiketMapping>(
                predicate: #Predicate<ComiketMapping> {
                    $0.mapID == mapID
                }
            )
            let mappings = try modelContext.fetch(mappingFetchDescriptor)
            let blockIDs = Set(mappings.map { $0.blockID })
            let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                predicate: #Predicate<ComiketCircle> {
                    blockIDs.contains($0.blockID) && $0.day == dayID
                }
            )
            let circles = try modelContext.fetch(fetchDescriptor)
            return Array(Set(circles.map { $0.genreID }))
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func blockIDs(inMap mapID: Int, onDay dayID: Int, withGenreIDs genreIDs: [Int]?) -> [Int] {
        do {
            let mappingFetchDescriptor = FetchDescriptor<ComiketMapping>(
                predicate: #Predicate<ComiketMapping> {
                    $0.mapID == mapID
                }
            )
            let mappings = try modelContext.fetch(mappingFetchDescriptor)
            let blockIDs = Set(mappings.map { $0.blockID })
            if let genreIDs, !genreIDs.isEmpty {
                let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                    predicate: #Predicate<ComiketCircle> {
                        blockIDs.contains($0.blockID) && $0.day == dayID && genreIDs.contains($0.genreID)
                    }
                )
                let circles = try modelContext.fetch(fetchDescriptor)
                return Array(Set(circles.map { $0.blockID }))
            } else {
                let fetchDescriptor = FetchDescriptor<ComiketCircle>(
                    predicate: #Predicate<ComiketCircle> {
                        blockIDs.contains($0.blockID) && $0.day == dayID
                    }
                )
                let circles = try modelContext.fetch(fetchDescriptor)
                return Array(Set(circles.map { $0.blockID }))
            }
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }

    func circles(withWebCatalogIDs webCatalogIDs: [Int]) -> [PersistentIdentifier] {
        do {
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

    func circles(forFavorites favoriteItems: [UserFavorites.Response.FavoriteItem]) -> [PersistentIdentifier] {
        do {
            let webCatalogIDs = favoriteItems.map { $0.circle.webCatalogID }
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

    func spaceNumberSuffixes(forWebCatalogIDs webCatalogIDs: [Int]) -> [Int: Int] {
        do {
            let extendedInformationFetchDescriptor = FetchDescriptor<ComiketCircleExtendedInformation>(
                predicate: #Predicate<ComiketCircleExtendedInformation> {
                    webCatalogIDs.contains($0.webCatalogID)
                }
            )
            let extendedInformation = try modelContext.fetch(extendedInformationFetchDescriptor)
            let webCatalogIDMappedToSpaceSubNo: [Int: Int] = extendedInformation
                .reduce(into: [:]) { result, extendedInformation in
                    do {
                        let circleID = extendedInformation.id
                        let circlesFetchDescriptor = FetchDescriptor<ComiketCircle>(
                            predicate: #Predicate<ComiketCircle> {
                                $0.id == circleID
                            }
                        )
                        let circles = try modelContext.fetch(circlesFetchDescriptor)
                        if let firstCircle = circles.first {
                            result[extendedInformation.webCatalogID] = firstCircle.spaceNumberSuffix
                        }
                    } catch {
                        // Intentionally left blank
                    }
                }
            return webCatalogIDMappedToSpaceSubNo
        } catch {
            debugPrint(error.localizedDescription)
            return webCatalogIDs.reduce(into: [:]) { result, webCatalogID in
                result[webCatalogID] = 0
            }
        }
    }
}
// swiftlint:enable type_body_length
