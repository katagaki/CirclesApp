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

    static func fetchCircles(
        genreID: Int?, mapID: Int?, blockID: Int?, dayID: Int?
    ) async -> [PersistentIdentifier] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        if let circleIdentifiers = await actor.circles(
            withGenre: genreID, inBlock: blockID, onDay: dayID
        ) {
            return circleIdentifiers
        } else if let mapID {
            return await actor.circles(inMap: mapID)
        }

        return []
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
