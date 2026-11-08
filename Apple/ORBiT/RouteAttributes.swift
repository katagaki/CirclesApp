#if os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

public struct RouteAttributes: ActivityAttributes, Sendable {

    public struct ContentState: Codable, Hashable, Sendable {
        public var instruction: String
        public var symbolName: String
        public var stopSpace: String
        public var stopName: String
        public var progress: String
        public var stopNumber: Int
        public var stopCount: Int
        public var isArriving: Bool

        public init(
            instruction: String, symbolName: String, stopSpace: String, stopName: String,
            progress: String, stopNumber: Int, stopCount: Int, isArriving: Bool
        ) {
            self.instruction = instruction
            self.symbolName = symbolName
            self.stopSpace = stopSpace
            self.stopName = stopName
            self.progress = progress
            self.stopNumber = stopNumber
            self.stopCount = stopCount
            self.isArriving = isArriving
        }
    }

    public var title: String
    public var hallName: String

    public init(title: String, hallName: String) {
        self.title = title
        self.hallName = hallName
    }
}
#endif
