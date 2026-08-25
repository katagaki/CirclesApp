//
//  OnHandAssetBuilder.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2026/08/25.
//

import CoreGraphics
import Foundation
import UIKit
import AXiS

@MainActor
enum OnHandAssetBuilder {

    static let spaceSize: CGFloat = 40.0
    static let cropSize: CGFloat = 420.0
    static let mapOutputSize: CGFloat = 300.0
    static let circleCutOutputSize: CGFloat = 220.0

    static func version(for payload: OnHandPayload) -> String {
        let identifiers = payload.favorites.map { String($0.id) }.sorted().joined(separator: ",")
        return "\(payload.eventNumber)-\(identifiers.hashValue)"
    }

    static func build(payload: OnHandPayload, database: Database) async -> OnHandAssetBundle? {
        guard !payload.favorites.isEmpty else { return nil }

        let circles = database.circles(payload.favorites.map { $0.id })
        guard !circles.isEmpty else { return nil }

        let circleCuts = await circleCuts(for: circles, database: database)
        let mapCrops = await mapCrops(for: circles, payload: payload, database: database)

        guard !circleCuts.isEmpty || !mapCrops.isEmpty else { return nil }

        return OnHandAssetBundle(
            version: version(for: payload),
            circleCuts: circleCuts,
            mapCrops: mapCrops
        )
    }

    // MARK: Circle cuts

    private static func circleCuts(
        for circles: [ComiketCircle],
        database: Database
    ) async -> [String: Data] {
        var circleCuts: [String: Data] = [:]
        for circle in circles {
            guard let image = await database.circleImageAsync(for: circle.id) else { continue }
            guard let data = jpegData(from: image, fittingWithin: circleCutOutputSize) else { continue }
            circleCuts[String(circle.id)] = data
        }
        return circleCuts
    }

    // MARK: Map crops

    private static func mapCrops(
        for circles: [ComiketCircle],
        payload: OnHandPayload,
        database: Database
    ) async -> [String: Data] {
        let fetcher = DataFetcher(database: database.newReadOnlyTextConnection())
        let hallFilenames = Dictionary(
            payload.favorites.map { ($0.id, $0.hallFilename) },
            uniquingKeysWith: { first, _ in first }
        )

        var mapIDsByBlockID: [Int: Int] = [:]
        for blockID in Set(circles.map { $0.blockID }) {
            mapIDsByBlockID[blockID] = await fetcher.mapID(forBlock: blockID)
        }

        var layoutsByMapID: [Int: [LayoutCatalogMapping]] = [:]
        var occupantCounts: [String: Int] = [:]
        let days = Set(circles.map { $0.day })
        for mapID in Set(mapIDsByBlockID.values) {
            let layouts = await fetcher.layoutMappings(inMap: mapID, useHighResolutionMaps: true)
            layoutsByMapID[mapID] = layouts
            for day in days {
                let mappings = await fetcher.layoutCatalogMappingToWebCatalogIDs(
                    forMappings: layouts,
                    on: day
                )
                for (mapping, webCatalogIDs) in mappings {
                    occupantCounts["\(day)-\(mapping.blockID)-\(mapping.spaceNumber)"] = webCatalogIDs.count
                }
            }
        }

        var mapImages: [String: UIImage] = [:]
        var mapCrops: [String: Data] = [:]

        for circle in circles {
            guard let filename = hallFilenames[circle.id],
                  let hall = ComiketHall(rawValue: filename),
                  let mapID = mapIDsByBlockID[circle.blockID],
                  let layout = layoutsByMapID[mapID]?.first(where: {
                      $0.blockID == circle.blockID && $0.spaceNumber == circle.spaceNumber
                  })
            else { continue }

            let imageKey = "\(circle.day)-\(filename)"
            var mapImage = mapImages[imageKey]
            if mapImage == nil {
                mapImage = await database.mapImageAsync(
                    for: hall,
                    on: circle.day,
                    usingHighDefinition: true
                )
                if let mapImage { mapImages[imageKey] = mapImage }
            }
            guard let mapImage else { continue }

            let spaceRect = spaceRect(
                layout: layout,
                spaceNumberSuffix: circle.spaceNumberSuffix,
                occupantCount: occupantCounts["\(circle.day)-\(circle.blockID)-\(circle.spaceNumber)"] ?? 1
            )
            guard let data = crop(mapImage, around: spaceRect) else { continue }
            mapCrops[String(circle.id)] = data
        }

        return mapCrops
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

    private static func crop(_ image: UIImage, around spaceRect: CGRect) -> Data? {
        let imageSize = CGSize(width: image.size.width, height: image.size.height)
        let side = min(cropSize, min(imageSize.width, imageSize.height))
        var originX = spaceRect.midX - side / 2.0
        var originY = spaceRect.midY - side / 2.0
        originX = min(max(0.0, originX), max(0.0, imageSize.width - side))
        originY = min(max(0.0, originY), max(0.0, imageSize.height - side))
        let scale = mapOutputSize / side
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: mapOutputSize, height: mapOutputSize),
            format: format
        )

        let rendered = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: mapOutputSize, height: mapOutputSize)))
            image.draw(in: CGRect(
                x: -originX * scale,
                y: -originY * scale,
                width: imageSize.width * scale,
                height: imageSize.height * scale
            ))

            let highlight = CGRect(
                x: (spaceRect.origin.x - originX) * scale,
                y: (spaceRect.origin.y - originY) * scale,
                width: spaceRect.width * scale,
                height: spaceRect.height * scale
            )
            let path = UIBezierPath(roundedRect: highlight.insetBy(dx: -2.0, dy: -2.0), cornerRadius: 4.0)
            UIColor.systemRed.withAlphaComponent(0.35).setFill()
            path.fill()
            UIColor.systemRed.setStroke()
            path.lineWidth = 3.0
            path.stroke()
        }

        return rendered.jpegData(compressionQuality: 0.75)
    }

    // MARK: Encoding

    private static func jpegData(from image: UIImage, fittingWithin maximumDimension: CGFloat) -> Data? {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0.0 else { return nil }
        let scale = min(1.0, maximumDimension / largestSide)
        let targetSize = CGSize(
            width: (image.size.width * scale).rounded(),
            height: (image.size.height * scale).rounded()
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
