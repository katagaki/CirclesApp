//
//  SharedBuysAttributes.swift
//  CiRCLES
//

import ActivityKit
import Foundation

struct SharedBuysAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var nextItemName: String
        var nextItemDetail: String
        var boughtCount: Int
        var assignedCount: Int
        var memberInitials: [String]

        var isComplete: Bool { assignedCount > 0 && boughtCount >= assignedCount }
    }

    var roomID: String
}
