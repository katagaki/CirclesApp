//
//  MapLayoutCache.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/11.
//

import Foundation
import SwiftUI

@Observable
class MapLayoutCache {
    
    struct CacheKey: Hashable {
        let mapID: Int
        let dateID: Int?
        let useHighResolutionMaps: Bool
    }
    
    struct CachedMapData: Sendable {
        let layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]]
        let layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]]
    }
    
    @ObservationIgnored private var cache: [CacheKey: CachedMapData] = [:]
    
    func getCachedData(for key: CacheKey) -> CachedMapData? {
        return cache[key]
    }
    
    func setCachedData(_ data: CachedMapData, for key: CacheKey) {
        cache[key] = data
    }
    
    func clearCache() {
        cache.removeAll()
    }
}
