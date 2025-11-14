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
        for (layout, webCatalogIDs) in layoutWebCatalogIDMappings {
            if layout.blockID == blockID && layout.spaceNumber == spaceNumber {
                let zoomFactor = zoomFactorDouble(zoomDivisor)
                let xMin: CGFloat = CGFloat(layout.positionX) / zoomFactor
                let yMin: CGFloat = CGFloat(layout.positionY) / zoomFactor
                let scaledSpaceSize = CGFloat(spaceSize) / zoomFactor
                
                // Get all circles in this space to determine positioning
                let count = webCatalogIDs.count
                guard count > 0 else { return }
                
                // Determine if we need to reverse the order based on layout type
                let needsReverse = layout.layoutType == .aOnBottom || layout.layoutType == .aOnRight
                
                // Find the index of this circle based on spaceNumberSuffix
                // The spaceNumberSuffix is the order index (0 for a, 1 for b, 2 for c)
                var circleIndex = spaceNumberSuffix
                
                // If the layout is reversed, we need to adjust the index
                if needsReverse {
                    circleIndex = count - 1 - spaceNumberSuffix
                }
                
                let countCGFloat = CGFloat(count)
                let indexCGFloat = CGFloat(circleIndex)
                
                // Calculate the highlight rectangle based on layout type
                let highlightRect: CGRect
                
                switch layout.layoutType {
                case .aOnLeft, .aOnRight, .unknown:
                    // Horizontal layout
                    let rectWidth = scaledSpaceSize / countCGFloat
                    highlightRect = CGRect(
                        x: xMin + indexCGFloat * rectWidth,
                        y: yMin,
                        width: rectWidth,
                        height: scaledSpaceSize
                    )
                case .aOnTop, .aOnBottom:
                    // Vertical layout
                    let rectHeight = scaledSpaceSize / countCGFloat
                    highlightRect = CGRect(
                        x: xMin,
                        y: yMin + indexCGFloat * rectHeight,
                        width: scaledSpaceSize,
                        height: rectHeight
                    )
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
