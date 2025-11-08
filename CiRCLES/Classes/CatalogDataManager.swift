//
//  CatalogDataManager.swift
//  CiRCLES
//
//  Created by GitHub Copilot on 2024/11/08.
//

import Foundation
import SwiftData

@Observable
@MainActor
class CatalogDataManager {
    
    // Cache for displayed circles based on selection criteria
    private var cachedCircles: [String: [ComiketCircle]] = [:]
    
    // Track if initial load has been completed
    var isInitialLoadCompleted: Bool = false
    
    func circles(for genreID: Int?, mapID: Int?, blockID: Int?, dateID: Int?, database: Database) async -> [ComiketCircle] {
        let cacheKey = makeCacheKey(genreID: genreID, mapID: mapID, blockID: blockID, dateID: dateID)
        
        // Return cached data if available
        if let cached = cachedCircles[cacheKey] {
            return cached
        }
        
        // Otherwise, load from database
        let circles = await loadCircles(genreID: genreID, mapID: mapID, blockID: blockID, dateID: dateID, database: database)
        cachedCircles[cacheKey] = circles
        return circles
    }
    
    private func loadCircles(genreID: Int?, mapID: Int?, blockID: Int?, dateID: Int?, database: Database) async -> [ComiketCircle] {
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
        
        var displayedCircles: [ComiketCircle] = []
        displayedCircles = database.circles(circleIdentifiers)
        if let dateID {
            displayedCircles.removeAll(where: { $0.day != dateID })
        }
        return displayedCircles
    }
    
    private func makeCacheKey(genreID: Int?, mapID: Int?, blockID: Int?, dateID: Int?) -> String {
        return "\(genreID ?? -1)_\(mapID ?? -1)_\(blockID ?? -1)_\(dateID ?? -1)"
    }
    
    func clearCache() {
        cachedCircles.removeAll()
        isInitialLoadCompleted = false
    }
}
