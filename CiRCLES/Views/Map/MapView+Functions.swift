//
//  MapView+Functions.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

extension MapView {
    func reloadAll() {
        withAnimation(.smooth.speed(2.0)) {
            removeAllMappings()
            reloadMapImage()
        } completion: {
            if let map = selections.map {
                let mapID = map.id
                let selectedDate = selections.date?.id
                let useHighResolutionMaps = useHighResolutionMaps
                let cacheKey = MapLayoutCache.CacheKey(
                    mapID: mapID,
                    dateID: selectedDate,
                    useHighResolutionMaps: useHighResolutionMaps
                )
                
                // Check cache first
                if let cachedData = mapLayoutCache.getCachedData(for: cacheKey) {
                    // Use cached data immediately
                    Task { @MainActor in
                        withAnimation(.smooth.speed(2.0)) {
                            self.layoutWebCatalogIDMappings = cachedData.layoutWebCatalogIDMappings
                            self.layoutFavoriteWebCatalogIDMappings = cachedData.layoutFavoriteWebCatalogIDMappings
                        }
                    }
                } else {
                    // Load data in background
                    Task.detached {
                        await self.loadMapData(
                            mapID: mapID,
                            selectedDate: selectedDate,
                            useHighResolutionMaps: useHighResolutionMaps,
                            cacheKey: cacheKey
                        )
                    }
                }
            }
        }
    }

    func removeAllMappings() {
        layoutWebCatalogIDMappings.removeAll()
        layoutFavoriteWebCatalogIDMappings.removeAll()
    }

    func reloadMapImage() {
        if let date = selections.date,
           let map = selections.map,
           let selectedHall = ComiketHall(rawValue: map.filename) {
            mapImage = database.mapImage(
                for: selectedHall,
                on: date.id,
                usingHighDefinition: useHighResolutionMaps
            )
            genreImage = database.genreImage(
                for: selectedHall,
                on: date.id,
                usingHighDefinition: useHighResolutionMaps
            )
        } else {
            mapImage = nil
            genreImage = nil
        }
    }

    func reloadMapLayouts(mapID: Int, selectedDate: Int?, useHighResolutionMaps: Bool) async {
        var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
        if let selectedDate {
            // Fetch map layouts
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            let layoutCatalogMappings = await actor.layoutMappings(
                inMap: mapID,
                useHighResolutionMaps: useHighResolutionMaps
            )
            // Create Layout Mapping <> Web Catalog ID mapping data
            if layoutCatalogMappings.count > 0 {
                layoutWebCatalogIDMappings = await actor.layoutCatalogMappingToWebCatalogIDs(
                    forMappings: layoutCatalogMappings, on: selectedDate
                )
            }
        }

        // Send results back to the view
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.layoutWebCatalogIDMappings = layoutWebCatalogIDMappings
            }
        }
    }
    
    func loadMapData(
        mapID: Int,
        selectedDate: Int?,
        useHighResolutionMaps: Bool,
        cacheKey: MapLayoutCache.CacheKey
    ) async {
        var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
        
        if let selectedDate {
            // Fetch map layouts
            let actor = DataFetcher(modelContainer: sharedModelContainer)
            let layoutCatalogMappings = await actor.layoutMappings(
                inMap: mapID,
                useHighResolutionMaps: useHighResolutionMaps
            )
            
            // Create Layout Mapping <> Web Catalog ID mapping data
            if layoutCatalogMappings.count > 0 {
                layoutWebCatalogIDMappings = await actor.layoutCatalogMappingToWebCatalogIDs(
                    forMappings: layoutCatalogMappings, on: selectedDate
                )
            }
        }
        
        // Process favorites concurrently with the layout data we just fetched
        let layoutFavoriteWebCatalogIDMappings = await processFavorites(
            layoutWebCatalogIDMappings: layoutWebCatalogIDMappings
        )
        
        // Cache the results
        let cachedData = MapLayoutCache.CachedMapData(
            layoutWebCatalogIDMappings: layoutWebCatalogIDMappings,
            layoutFavoriteWebCatalogIDMappings: layoutFavoriteWebCatalogIDMappings
        )
        await MainActor.run {
            mapLayoutCache.setCachedData(cachedData, for: cacheKey)
        }
        
        // Send results back to the view
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.layoutWebCatalogIDMappings = layoutWebCatalogIDMappings
                self.layoutFavoriteWebCatalogIDMappings = layoutFavoriteWebCatalogIDMappings
            }
        }
    }

    func reloadFavorites() async {
        let layoutFavoriteWebCatalogIDMappings = await processFavorites(
            layoutWebCatalogIDMappings: layoutWebCatalogIDMappings
        )
        
        await MainActor.run {
            withAnimation(.smooth.speed(2.0)) {
                self.layoutFavoriteWebCatalogIDMappings = layoutFavoriteWebCatalogIDMappings
            }
        }
    }
    
    func processFavorites(
        layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]]
    ) async -> [LayoutCatalogMapping: [Int: WebCatalogColor?]] {
        let actor = DataFetcher(modelContainer: sharedModelContainer)
        
        // Create favorites mapping for Web Catalog IDs
        let layoutFavoriteWebCatalogIDMappings = mapFavoriteMappings(
            layoutWebCatalogIDMappings
        )
        
        // List out all Web Catalog IDs
        let webCatalogIDs: [Int] = Array(Set(
            layoutFavoriteWebCatalogIDMappings.values
                .reduce(into: [] as [Int]) { result, webCatalogIDs in
                    result.append(contentsOf: webCatalogIDs.keys)
                }
        ))
        
        // Return early if there are no web catalog IDs to process
        guard !webCatalogIDs.isEmpty else {
            return layoutFavoriteWebCatalogIDMappings
        }
        
        // Map all Web Catalog IDs to space number suffixes
        let spaceNumberSuffixes = await actor.spaceNumberSuffixes(
            forWebCatalogIDs: webCatalogIDs
        )
        
        // Replace Web Catalog IDs with space number suffixes
        let layoutFavoriteWebCatalogIDSorted = layoutFavoriteWebCatalogIDMappings
            .reduce(into: [LayoutCatalogMapping: [Int: WebCatalogColor?]]()) { result, keyValue in
                let mapping = keyValue.key
                let colorMapping = keyValue.value
                result[mapping] = colorMapping
                    .reduce(into: [Int: WebCatalogColor?]()) { result, keyValue in
                        let webCatalogID = keyValue.key
                        let color = keyValue.value
                        result[spaceNumberSuffixes[webCatalogID] ?? webCatalogID] = color
                    }
            }
        
        return layoutFavoriteWebCatalogIDSorted
    }

    func mapFavoriteMappings(
        _ layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]]
    ) -> [LayoutCatalogMapping: [Int: WebCatalogColor?]] {
        var layoutFavoriteWebCatalogIDMappings: [LayoutCatalogMapping: [Int: WebCatalogColor?]] = [:]
        if let webCatalogIDMappedItems = favorites.wcIDMappedItems {
            for (webCatalogID, favoriteItem) in webCatalogIDMappedItems {
                // 1. Find the layout catalog mapping that matches the Web Catalog ID
                let matchingLayoutMaps: [LayoutCatalogMapping: [Int]] = layoutWebCatalogIDMappings
                    .filter { $1.contains(webCatalogID) }

                // 2. Ensure that only one layout is selected
                if let (matchedLayoutMap, _) = matchingLayoutMaps.first {
                    // 3. Set up the sub-dictionary for the favorites mapping
                    if layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] == nil {
                        let webCatalogIDs = layoutWebCatalogIDMappings[matchedLayoutMap] ?? []
                        layoutFavoriteWebCatalogIDMappings[matchedLayoutMap] = webCatalogIDs
                            .reduce(into: [:]) { partialResult, webCatalogID in
                                let nilColor: WebCatalogColor? = nil
                                partialResult[webCatalogID] = nilColor
                            }
                    }

                    // 4. Set the color for the Web Catalog ID in the favorites mapping
                    layoutFavoriteWebCatalogIDMappings[matchedLayoutMap]?[webCatalogID] = favoriteItem.favorite.color
                }
            }
            // 5. Change keys to space sub number to force MapFavoriteLayerBlock to sort correctly
            // TODO
        }
        return layoutFavoriteWebCatalogIDMappings
    }
}
