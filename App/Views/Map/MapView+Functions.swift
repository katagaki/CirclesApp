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
        } completion: {
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
    }

    func reloadMapImage() async {
        guard let date = selections.date,
              let map = selections.map,
              let selectedHall = ComiketHall(rawValue: map.filename) else {
            mapImage = nil
            genreImage = nil
            return
        }
        let newMapImage = await database.mapImageAsync(
            for: selectedHall,
            on: date.id,
            usingHighDefinition: useHighResolutionMaps
        )
        let newGenreImage = await database.genreImageAsync(
            for: selectedHall,
            on: date.id,
            usingHighDefinition: useHighResolutionMaps
        )
        withAnimation(.smooth.speed(2.0)) {
            mapImage = newMapImage
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
