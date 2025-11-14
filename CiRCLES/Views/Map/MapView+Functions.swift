//
//  MapView+Functions.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/08.
//

import SwiftUI

extension MapView {
    func updateCanvasSize(_ image: UIImage) {
        let zoomFactor = zoomFactor(zoomDivisor)
        canvasSize = CGSize(
            width: image.size.width / zoomFactor,
            height: image.size.height / zoomFactor
        )
    }

    func reloadAll() {
        withAnimation(.smooth.speed(2.0)) {
            removeAllMappings()
            reloadMapImage()
        } completion: {
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

    func removeAllMappings() {
        layoutWebCatalogIDMappings.removeAll()
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

    func highlightCircle(_ circle: ComiketCircle) async {
        // Get the layout mapping for this circle
        let blockID = circle.blockID
        let spaceNumber = circle.spaceNumber
        let spaceNumberSuffix = circle.spaceNumberSuffix
        
        // Find the matching layout mapping
        for (layout, _) in layoutWebCatalogIDMappings {
            if layout.blockID == blockID && layout.spaceNumber == spaceNumber {
                let zoomFactor = zoomFactorDouble(zoomDivisor)
                let xMin: Int = Int(Double(layout.positionX) / zoomFactor)
                let yMin: Int = Int(Double(layout.positionY) / zoomFactor)
                let spaceSize = Int(Double(spaceSize) / zoomFactor)
                
                // Calculate position based on spaceNumberSuffix and layout type
                var highlightRect: CGRect
                let halfSpace = spaceSize / 2
                
                switch layout.layoutType {
                case .aOnLeft: // a is on left, b is on right
                    if spaceNumberSuffix == 0 { // a
                        highlightRect = CGRect(x: xMin, y: yMin, width: halfSpace, height: spaceSize)
                    } else { // b
                        highlightRect = CGRect(x: xMin + halfSpace, y: yMin, width: halfSpace, height: spaceSize)
                    }
                case .aOnBottom: // a is on bottom, b is on top
                    if spaceNumberSuffix == 0 { // a
                        highlightRect = CGRect(x: xMin, y: yMin + halfSpace, width: spaceSize, height: halfSpace)
                    } else { // b
                        highlightRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: halfSpace)
                    }
                case .aOnRight: // a is on right, b is on left
                    if spaceNumberSuffix == 0 { // a
                        highlightRect = CGRect(x: xMin + halfSpace, y: yMin, width: halfSpace, height: spaceSize)
                    } else { // b
                        highlightRect = CGRect(x: xMin, y: yMin, width: halfSpace, height: spaceSize)
                    }
                case .aOnTop: // a is on top, b is on bottom
                    if spaceNumberSuffix == 0 { // a
                        highlightRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: halfSpace)
                    } else { // b
                        highlightRect = CGRect(x: xMin, y: yMin + halfSpace, width: spaceSize, height: halfSpace)
                    }
                case .unknown:
                    // For unknown layout, highlight the entire space
                    highlightRect = CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)
                }
                
                // Set scroll position to center of highlight
                let scrollPosition = CGPoint(
                    x: highlightRect.midX,
                    y: highlightRect.midY
                )
                
                await MainActor.run {
                    // Close any open popover
                    popoverData = nil
                    
                    // Set scroll position
                    scrollToPosition = scrollPosition
                    
                    // Trigger highlight with blink
                    highlightData = HighlightData(sourceRect: highlightRect, shouldBlink: true)
                }
                
                return
            }
        }
    }

}
