//
//  LayoutCatalogMapping.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/09/07.
//

struct LayoutCatalogMapping: Hashable, Sendable {
    var blockID: Int
    var spaceNumber: Int
    var positionX: Int
    var positionY: Int

    init(blockID: Int, spaceNumber: Int, positionX: Int, positionY: Int) {
        self.blockID = blockID
        self.spaceNumber = spaceNumber
        self.positionX = positionX
        self.positionY = positionY
    }

    init(blockID: Int, spaceNumber: Int) {
        self.blockID = blockID
        self.spaceNumber = spaceNumber
        self.positionX = 0
        self.positionY = 0
    }

    func viewID() -> String {
        return "\(blockID),\(spaceNumber)"
    }

    static func == (lhs: LayoutCatalogMapping, rhs: LayoutCatalogMapping) -> Bool {
        return lhs.blockID == rhs.blockID && lhs.spaceNumber == rhs.spaceNumber
    }
}
