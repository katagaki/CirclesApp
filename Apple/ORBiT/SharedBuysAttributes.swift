#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

public struct SharedBuysAttributes: ActivityAttributes, Sendable {

    public struct ContentState: Codable, Hashable, Sendable {
        public var nextItemName: String
        public var nextItemDetail: String
        public var circleName: String?
        public var circleSpace: String?
        public var boughtCount: Int
        public var assignedCount: Int
        public var memberNames: [String]
        public var imageKey: String?
        public var canFlip: Bool

        public var isComplete: Bool { assignedCount > 0 && boughtCount >= assignedCount }
    }

    public var roomID: String
}
#endif
