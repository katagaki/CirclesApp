//
//  CatalogCache.swift
//  CiRCLES
//
//  Created by Copilot on 2025/11/10.
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
class CatalogCache {
    
    var displayedCircles: [ComiketCircle] = []
    var isInitialLoadCompleted: Bool = false
    
    private var lastGenreID: Int?
    private var lastMapID: Int?
    private var lastBlockID: Int?
    
    func shouldReload(genreID: Int?, mapID: Int?, blockID: Int?) -> Bool {
        // Check if the selection has changed
        if lastGenreID != genreID || lastMapID != mapID || lastBlockID != blockID {
            lastGenreID = genreID
            lastMapID = mapID
            lastBlockID = blockID
            return true
        }
        return !isInitialLoadCompleted
    }
    
    func updateCircles(_ circles: [ComiketCircle]) {
        displayedCircles = circles
        isInitialLoadCompleted = true
    }
    
    func reset() {
        displayedCircles.removeAll()
        isInitialLoadCompleted = false
        lastGenreID = nil
        lastMapID = nil
        lastBlockID = nil
    }
}
