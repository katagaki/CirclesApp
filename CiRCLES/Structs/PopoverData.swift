//
//  PopoverData.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2025/06/07.
//

import Foundation

struct PopoverData: Identifiable, Equatable {
    var layout: LayoutCatalogMapping
    var idSet: WebCatalogIDSet
    var reversed: Bool = false
    var sourceRect: CGRect = .null

    var id: String {
        "ID_\(idSet.id),L_\(layout.viewID())"
    }
    var ids: [Int] {
        idSet.ids
    }
    var layoutId: String {
        "Layout.\(layout.blockID).\(layout.spaceNumber)"
    }

    var sourceWidth: CGFloat { sourceRect.width }
    var sourceHeight: CGFloat { sourceRect.height }
    var sourceMidX: CGFloat { sourceRect.midX }
    var sourceMidY: CGFloat { sourceRect.midY }

    static func == (lhs: PopoverData, rhs: PopoverData) -> Bool {
        lhs.id == rhs.id
    }
}

struct WebCatalogIDSet: Identifiable, Equatable {
    var ids: [Int]

    var id: String {
        ids.description
    }

    static func == (lhs: WebCatalogIDSet, rhs: WebCatalogIDSet) -> Bool {
        lhs.ids.description == rhs.ids.description
    }
}
