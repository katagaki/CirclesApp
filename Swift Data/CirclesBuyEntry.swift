//
//  CirclesBuyEntry.swift
//  CiRCLES
//
//  Created by Claude on 2026/03/24.
//

import Foundation
import SwiftData

@Model
final class CirclesBuyEntry {
    var circleID: Int
    var eventNumber: Int
    var items: [BuyItem]

    init(circleID: Int, eventNumber: Int, items: [BuyItem] = []) {
        self.circleID = circleID
        self.eventNumber = eventNumber
        self.items = items
    }

    struct BuyItem: Codable, Identifiable, Hashable {
        var id: UUID
        var name: String
        var cost: Int
        var imageData: Data?

        init(id: UUID = UUID(), name: String, cost: Int, imageData: Data? = nil) {
            self.id = id
            self.name = name
            self.cost = cost
            self.imageData = imageData
        }
    }
}
