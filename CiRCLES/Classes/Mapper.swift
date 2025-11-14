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
}
