//
//  SharedBuysAttributes.swift
//  CiRCLES
//

#if os(iOS)
import ActivityKit
import Foundation

public struct SharedBuysAttributes: ActivityAttributes, Sendable {

    public struct ContentState: Codable, Hashable, Sendable {
        public var nextItemName: String
        public var nextItemDetail: String
        public var boughtCount: Int
        public var assignedCount: Int
        public var memberInitials: [String]

        public var isComplete: Bool { assignedCount > 0 && boughtCount >= assignedCount }
    }

    public var roomID: String
}
#endif
