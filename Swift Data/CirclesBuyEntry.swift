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

    enum BuyItemStatus: Int, Codable, Hashable {
        case pending = 0
        case bought = 1
        case cancelled = 2

        var next: BuyItemStatus {
            switch self {
            case .pending: .bought
            case .bought: .cancelled
            case .cancelled: .pending
            }
        }
    }

    struct BuyItem: Codable, Identifiable, Hashable {
        var id: UUID
        var name: String
        var cost: Int
        var imageData: Data?
        var status: BuyItemStatus

        init(id: UUID = UUID(), name: String, cost: Int, imageData: Data? = nil, status: BuyItemStatus = .pending) {
            self.id = id
            self.name = name
            self.cost = cost
            self.imageData = imageData
            self.status = status
        }
    }
}
