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
        mapper.canvasSize = CGSize(
            width: image.size.width / zoomFactor,
            height: image.size.height / zoomFactor
        )
    }

    func reloadAll() {
        withAnimation(.smooth.speed(2.0)) {
            mapper.removeAllLayouts()
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
                mapper.layouts = layoutWebCatalogIDMappings
            }
        }
    }

    // swiftlint:disable function_body_length
    func highlightCircle(_ circle: ComiketCircle) async {
        let blockID = circle.blockID
        let spaceNumber = circle.spaceNumber
        let spaceNumberSuffix = circle.spaceNumberSuffix

        guard let (layout, webCatalogIDs) = mapper.layouts.first(
            where: { (layout: LayoutCatalogMapping, _) in
                layout.blockID == blockID && layout.spaceNumber == spaceNumber
            }
        ) else {
            // TODO: Show message telling user the circle is not in this map
            return
        }

        let zoomFactor = zoomFactorDouble(zoomDivisor)
        let xMin: CGFloat = CGFloat(layout.positionX) / zoomFactor
        let yMin: CGFloat = CGFloat(layout.positionY) / zoomFactor
        let scaledSpaceSize = CGFloat(spaceSize) / zoomFactor

        let count = webCatalogIDs.count
        guard count > 0 else { return }

        var circleIndex = spaceNumberSuffix

        if layout.layoutType == .aOnBottom || layout.layoutType == .aOnRight {
            circleIndex = count - 1 - spaceNumberSuffix
        }

        let countCGFloat = CGFloat(count)
        let indexCGFloat = CGFloat(circleIndex)

        let highlightRect: CGRect
        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            let rectWidth = scaledSpaceSize / countCGFloat
            highlightRect = CGRect(
                x: xMin + indexCGFloat * rectWidth,
                y: yMin,
                width: rectWidth,
                height: scaledSpaceSize
            )
        case .aOnTop, .aOnBottom:
            let rectHeight = scaledSpaceSize / countCGFloat
            highlightRect = CGRect(
                x: xMin,
                y: yMin + indexCGFloat * rectHeight,
                width: scaledSpaceSize,
                height: rectHeight
            )
        }

        let scrollPosition = CGPoint(
            x: highlightRect.midX,
            y: highlightRect.midY
        )

        await MainActor.run {
            mapper.popoverData = nil
            mapper.scrollToPosition = scrollPosition
            mapper.highlightData = HighlightData(
                sourceRect: highlightRect, shouldBlink: true
            )
        }
    }
    // swiftlint:enable function_body_length

}
