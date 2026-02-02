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
        genreIDs: [Int]?, mapID: Int?, blockIDs: [Int]?, dayID: Int?, database: Database
    ) async -> [Int] {
        let actor = DataFetcher(database: await database.getTextDatabase())
        return await actor.circles(
            inMap: mapID,
            withGenre: genreIDs,
            inBlock: blockIDs,
            onDay: dayID
        )
    }

    static func fetchGenreIDs(inMap mapID: Int, onDay dayID: Int, database: Database) async -> [Int] {
        let actor = DataFetcher(database: await database.getTextDatabase())
        return await actor.genreIDs(inMap: mapID, onDay: dayID)
    }

    static func fetchBlockIDs(
        inMap mapID: Int,
        onDay dayID: Int,
        withGenreIDs genreIDs: [Int]?,
        database: Database
    ) async -> [Int] {
        let actor = DataFetcher(database: await database.getTextDatabase())
        return await actor.blockIDs(inMap: mapID, onDay: dayID, withGenreIDs: genreIDs)
    }

    static func searchCircles(_ searchTerm: String, database: Database) async -> [Int]? {
        let actor = DataFetcher(database: await database.getTextDatabase())
        if searchTerm.trimmingCharacters(in: .whitespaces).count >= 2 {
            let circleIdentifiers = await actor.circles(containing: searchTerm)
            return circleIdentifiers
        } else {
            return nil
        }
    }
}
