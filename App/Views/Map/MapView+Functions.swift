//
//  MapView+Functions.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI
import AXiS

extension MapView {
    func updateCanvasSize(_ image: UIImage) {
        mapper.canvasSize = CGSize(
            width: image.size.width,
            height: image.size.height
        )
    }

    func reloadAll() {
        withAnimation(.smooth.speed(2.0)) {
            mapper.removeAllLayouts()
            mapImage = nil
            genreImage = nil
        }
        // Kick off the image and layout loads immediately rather than waiting for the
        // clear animation to finish, so the map and its overlays appear as soon as possible.
        Task { await reloadMapImage() }
        if let map = selections.map {
            let mapID = map.id
            let selectedDate = selections.date?.id
            let useHighResolutionMaps = useHighResolutionMaps
            Task.detached {
                await reloadMapLayouts(
                    mapID: mapID,
                    selectedDate: selectedDate,
                    useHighResolutionMaps: useHighResolutionMaps
                )
            }
        }
    }

    func reloadMapImage() async {
        guard let date = selections.date,
              let map = selections.map,
              let selectedHall = ComiketHall(rawValue: map.filename) else {
            mapImage = nil
            genreImage = nil
            return
        }
        // Show the base map (and everything layered on it, including the filter dim) as
        // soon as it decodes — don't block it behind the optional genre overlay.
        let newMapImage = await database.mapImageAsync(
            for: selectedHall,
            on: date.id,
            usingHighDefinition: useHighResolutionMaps
        )
        withAnimation(.smooth.speed(2.0)) {
            mapImage = newMapImage
        }
        await reloadGenreImage()
    }

    func reloadGenreImage() async {
        guard showGenreOverlay,
              let date = selections.date,
              let map = selections.map,
              let selectedHall = ComiketHall(rawValue: map.filename) else {
            genreImage = nil
            return
        }
        let newGenreImage = await database.genreImageAsync(
            for: selectedHall,
            on: date.id,
            usingHighDefinition: useHighResolutionMaps
        )
        withAnimation(.smooth.speed(2.0)) {
            genreImage = newGenreImage
        }
    }

    func reloadMapLayouts(mapID: Int, selectedDate: Int?, useHighResolutionMaps: Bool) async {
        var layoutWebCatalogIDMappings: [LayoutCatalogMapping: [Int]] = [:]
        if let selectedDate {
            let actor = DataFetcher(database: database.newReadOnlyTextConnection())
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
                mapper.layouts = layoutWebCatalogIDMappings
            }
        }
    }
}
