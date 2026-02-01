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
        genreIDs: [Int]?, mapID: Int?, blockIDs: [Int]?, dayID: Int?
    ) async -> [PersistentIdentifier] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)

        var circleIdentifiers: [PersistentIdentifier] = []
        if let mapID {
            circleIdentifiers = await actor.circles(inMap: mapID)
        }

        if let filteredCircleIdentifiers = await actor.circles(
            withGenre: genreIDs, inBlock: blockIDs, onDay: dayID
        ) {
            return filteredCircleIdentifiers.filter { identifier in
                circleIdentifiers.contains(identifier)
            }
        } else {
            return circleIdentifiers
        }

    }

    static func fetchGenreIDs(inMap mapID: Int, onDay dayID: Int) async -> [Int] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        return await actor.genreIDs(inMap: mapID, onDay: dayID)
    }

    static func fetchBlockIDs(inMap mapID: Int, onDay dayID: Int, withGenreIDs genreIDs: [Int]?) async -> [Int] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        return await actor.blockIDs(inMap: mapID, onDay: dayID, withGenreIDs: genreIDs)
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
