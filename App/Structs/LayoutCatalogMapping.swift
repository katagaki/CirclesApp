//
//  LayoutCatalogMapping.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

struct LayoutCatalogMapping: Hashable, Equatable, Sendable {
    var blockID: Int
    var spaceNumber: Int
    var positionX: Int
    var positionY: Int
    var layoutType: ComiketLayout.LayoutType

    func viewID() -> String {
        return "\(blockID),\(spaceNumber)"
    }

    static func == (lhs: LayoutCatalogMapping, rhs: LayoutCatalogMapping) -> Bool {
        return lhs.blockID == rhs.blockID && lhs.spaceNumber == rhs.spaceNumber
    }
}
