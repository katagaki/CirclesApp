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
        guard !circleCuts.isEmpty else { return nil }

        return OnHandAssetBundle(
            version: version(for: payload),
            circleCuts: circleCuts,
            mapCrops: [:]
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
