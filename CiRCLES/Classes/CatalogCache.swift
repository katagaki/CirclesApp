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

    var invalidationID: String = ""
    var isLoading: Bool = false

    static func fetchCircles(
        genreID: Int?, mapID: Int?, blockID: Int?, dayID: Int?
    ) async -> [PersistentIdentifier] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleIdentifiers: [PersistentIdentifier] = []
        if let mapID {
            circleIdentifiers = await actor.circles(inMap: mapID)
        }

        if let filteredCircleIdentifiers = await actor.circles(
            withGenre: genreID, inBlock: blockID, onDay: dayID
        ) {
            return filteredCircleIdentifiers.filter { identifier in
                circleIdentifiers.contains(identifier)
            }
        } else {
            return circleIdentifiers
        }

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
