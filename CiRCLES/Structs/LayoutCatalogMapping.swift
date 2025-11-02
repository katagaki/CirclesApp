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

    init(blockID: Int, spaceNumber: Int, positionX: Int, positionY: Int, layoutType: ComiketLayout.LayoutType) {
        self.blockID = blockID
        self.spaceNumber = spaceNumber
        self.positionX = positionX
        self.positionY = positionY
        self.layoutType = layoutType
    }

    init(blockID: Int, spaceNumber: Int) {
        self.blockID = blockID
        self.spaceNumber = spaceNumber
        self.positionX = 0
        self.positionY = 0
        self.layoutType = .unknown
    }

    func viewID() -> String {
        return "\(blockID),\(spaceNumber)"
    }

    static func == (lhs: LayoutCatalogMapping, rhs: LayoutCatalogMapping) -> Bool {
        return lhs.blockID == rhs.blockID && lhs.spaceNumber == rhs.spaceNumber
    }
}
