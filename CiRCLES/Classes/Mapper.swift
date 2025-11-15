//
//  Mapper.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/11/14.
//

import CoreGraphics
import Observation
import UIKit

@Observable
class Mapper {
    typealias Layouts = [LayoutCatalogMapping: [Int]]

    // Canvas info
    var canvasSize: CGSize = .zero

    // Layout (interactive) layer
    var layouts: Layouts = [:]

    // Popover layer
    let popoverWidth: CGFloat = 240.0
    let popoverHeight: CGFloat = (16.0 * 2) + (70.0 * 2) + 8.0
    let popoverDistance: CGFloat = 8.0
    let popoverEdgePadding: CGFloat = 16.0

    var popoverData: PopoverData?
    var popoverPosition: CGPoint?
    var scrollToPosition: CGPoint?

    // Highlight layer
    var highlightData: HighlightData?
    var highlightTarget: ComiketCircle?

    func removeAllLayouts() {
        layouts.removeAll()
    }

    // swiftlint:disable function_body_length
    @MainActor
    func highlightCircle(
        zoomDivisor: Int,
        spaceSize: Int
    ) async -> Bool {
        guard let circle = highlightTarget else { return false }
        let blockID = circle.blockID
        let spaceNumber = circle.spaceNumber
        let spaceNumberSuffix = circle.spaceNumberSuffix

        guard let (layout, webCatalogIDs) = self.layouts.first(
            where: { (layout: LayoutCatalogMapping, _) in
                layout.blockID == blockID && layout.spaceNumber == spaceNumber
            }
        ) else {
            return false
        }

        let zoomFactor = zoomFactorDouble(zoomDivisor)
        let xMin: CGFloat = CGFloat(layout.positionX) / zoomFactor
        let yMin: CGFloat = CGFloat(layout.positionY) / zoomFactor
        let scaledSpaceSize = CGFloat(spaceSize) / zoomFactor

        let count = webCatalogIDs.count
        guard count > 0 else { return false }

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

        self.popoverData = nil
        self.scrollToPosition = scrollPosition
        self.highlightData = HighlightData(
            sourceRect: highlightRect, shouldBlink: true
        )

        return true
    }
    // swiftlint:enable function_body_length
}
