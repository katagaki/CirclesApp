//
//  CatalogCache.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import SQLite
import SwiftData
import SwiftUI

@Observable
class CatalogCache {

    var displayedCircles: [ComiketCircle] = []
    var searchedCircles: [ComiketCircle]?

    var invalidationID: String = ""
    var isLoading: Bool = false

    static func fetchCircles(
        genreIDs: [Int]?, mapID: Int?, blockIDs: [Int]?, dayID: Int?, database: Connection?
    ) async -> [Int] {
        let actor = DataFetcher(database: database)

        var circleIdentifiers: [Int] = []
        if let mapID {
            circleIdentifiers = await actor.circles(inMap: mapID)
        }

        if let filteredCircleIdentifiers = await actor.circles(
            withGenre: genreIDs, inBlock: blockIDs, onDay: dayID
        ) {
            if circleIdentifiers.isEmpty {
                return filteredCircleIdentifiers
            } else {
                return filteredCircleIdentifiers.filter { identifier in
                    circleIdentifiers.contains(identifier)
                }
            }
        } else {
            return circleIdentifiers
        }

    }

    static func fetchGenreIDs(inMap mapID: Int, onDay dayID: Int, database: Connection?) async -> [Int] {
        let actor = DataFetcher(database: database)
        return await actor.genreIDs(inMap: mapID, onDay: dayID)
    }

    static func fetchBlockIDs(
        inMap mapID: Int,
        onDay dayID: Int,
        withGenreIDs genreIDs: [Int]?,
        database: Connection?
    ) async -> [Int] {
        let actor = DataFetcher(database: database)
        return await actor.blockIDs(inMap: mapID, onDay: dayID, withGenreIDs: genreIDs)
    }

    static func searchCircles(_ searchTerm: String, database: Connection?) async -> [Int]? {
        let actor = DataFetcher(database: database)
        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)
            return circleIdentifiers
        } else {
            return nil
        }
    }
}
