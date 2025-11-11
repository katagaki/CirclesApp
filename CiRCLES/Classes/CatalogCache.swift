//
//  CatalogCache.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import SwiftData
import SwiftUI

@Observable
class CatalogCache {

    var displayedCircles: [ComiketCircle] = []
    var searchedCircles: [ComiketCircle]?

    var isInitialLoadCompleted: Bool = false
    var isLoading: Bool = false

    static func displayedCircles(
        genreID: Int?, mapID: Int?, blockID: Int?
    ) async -> [PersistentIdentifier] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleIdentifiersByGenre: [PersistentIdentifier]?
        var circleIdentifiersByMap: [PersistentIdentifier]?
        var circleIdentifiersByBlock: [PersistentIdentifier]?
        var circleIdentifiers: [PersistentIdentifier] = []

        if let genreID {
            circleIdentifiersByGenre = await actor.circles(withGenre: genreID)
        }
        if let mapID {
            circleIdentifiersByMap = await actor.circles(inMap: mapID)
        }
        if let blockID {
            circleIdentifiersByBlock = await actor.circles(inBlock: blockID)
        }

        if let circleIdentifiersByGenre {
            circleIdentifiers = circleIdentifiersByGenre
        }
        if let circleIdentifiersByMap {
            if circleIdentifiers.isEmpty {
                circleIdentifiers = circleIdentifiersByMap
            } else {
                circleIdentifiers = Array(
                    Set(circleIdentifiers).intersection(Set(circleIdentifiersByMap))
                )
            }
        }
        if let circleIdentifiersByBlock {
            circleIdentifiers = Array(
                Set(circleIdentifiers).intersection(Set(circleIdentifiersByBlock))
            )
        }
        return circleIdentifiers
    }

    static func searchCircles(_ searchTerm: String) async -> [PersistentIdentifier]? {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)
            return circleIdentifiers
        } else {
            return nil
        }
    }
}
