//
//  OnHandMapGeometry.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/26.
//

import CoreGraphics
import Foundation
import AXiS

@MainActor
enum OnHandMapGeometry {

    static let spaceSize: CGFloat = 40.0

    static func mapKey(day: Int, hallFilename: String) -> String {
        "\(day)-\(hallFilename)"
    }

    static func placements(
        for circles: [ComiketCircle],
        hallFilenames: [Int: String],
        database: Database
    ) async -> [Int: OnHandRect] {
        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())

        var mapIDsByBlockID: [Int: Int] = [:]
        for blockID in Set(circles.map { $0.blockID }) {
            guard !Task.isCancelled else { return [:] }
            mapIDsByBlockID[blockID] = await fetcher.mapID(forBlock: blockID)
        }

        var layoutsByMapID: [Int: [LayoutCatalogMapping]] = [:]
        var occupantCounts: [String: Int] = [:]
        let days = Set(circles.map { $0.day })
        for mapID in Set(mapIDsByBlockID.values) {
            guard !Task.isCancelled else { return [:] }
            let layouts = await fetcher.layoutMappings(inMap: mapID, useHighResolutionMaps: true)
            layoutsByMapID[mapID] = layouts
            for day in days {
                guard !Task.isCancelled else { return [:] }
                let mappings = await fetcher.layoutCatalogMappingToWebCatalogIDs(
                    forMappings: layouts,
                    on: day
                )
                for (mapping, webCatalogIDs) in mappings {
                    occupantCounts["\(day)-\(mapping.blockID)-\(mapping.spaceNumber)"] = webCatalogIDs.count
                }
            }
        }

        var sourceSizes: [String: CGSize] = [:]
        var placements: [Int: OnHandRect] = [:]

        for circle in circles {
            guard !Task.isCancelled else { return placements }
            guard let filename = hallFilenames[circle.id],
                  let hall = ComiketHall(rawValue: filename),
                  let mapID = mapIDsByBlockID[circle.blockID],
                  let layout = layoutsByMapID[mapID]?.first(where: {
                      $0.blockID == circle.blockID && $0.spaceNumber == circle.spaceNumber
                  })
            else { continue }

            let key = mapKey(day: circle.day, hallFilename: filename)
            var sourceSize = sourceSizes[key]
            if sourceSize == nil {
                sourceSize = await database.mapImageAsync(
                    for: hall,
                    on: circle.day,
                    usingHighDefinition: true
                )?.size
                if let sourceSize { sourceSizes[key] = sourceSize }
            }
            guard let sourceSize, sourceSize.width > 0.0, sourceSize.height > 0.0 else { continue }

            let rect = spaceRect(
                layout: layout,
                spaceNumberSuffix: circle.spaceNumberSuffix,
                occupantCount: occupantCounts["\(circle.day)-\(circle.blockID)-\(circle.spaceNumber)"] ?? 1
            )
            placements[circle.id] = OnHandRect(
                originX: rect.origin.x / sourceSize.width,
                originY: rect.origin.y / sourceSize.height,
                width: rect.width / sourceSize.width,
                height: rect.height / sourceSize.height
            )
        }

        return placements
    }

    private static func spaceRect(
        layout: LayoutCatalogMapping,
        spaceNumberSuffix: Int,
        occupantCount: Int
    ) -> CGRect {
        let xMin = CGFloat(layout.positionX)
        let yMin = CGFloat(layout.positionY)
        let full = CGRect(x: xMin, y: yMin, width: spaceSize, height: spaceSize)

        let count = max(1, occupantCount)
        var index = spaceNumberSuffix
        if layout.layoutType == .aOnBottom || layout.layoutType == .aOnRight {
            index = count - 1 - spaceNumberSuffix
        }
        guard index >= 0, index < count else { return full }

        switch layout.layoutType {
        case .aOnLeft, .aOnRight, .unknown:
            let width = spaceSize / CGFloat(count)
            return CGRect(x: xMin + CGFloat(index) * width, y: yMin, width: width, height: spaceSize)
        case .aOnTop, .aOnBottom:
            let height = spaceSize / CGFloat(count)
            return CGRect(x: xMin, y: yMin + CGFloat(index) * height, width: spaceSize, height: height)
        }
    }
}
