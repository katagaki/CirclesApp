//
//  WebCatalogEvent.swift
//  RADiUS
//
//  Created by シン・ジャスティン on 2024/07/15.
//

// swiftlint:disable nesting
public struct WebCatalogEvent: Codable {
    public let status: String
    public let response: Response

    public struct Response: Codable, Sendable {
        public let list: [Event]
        public let latestEventID: Int
        public let latestEventNumber: Int

        public struct Event: Codable, Equatable, Sendable {
            public let id: Int
            public let number: Int

            public init(id: Int, number: Int) {
                self.id = id
                self.number = number
            }

            enum CodingKeys: String, CodingKey {
                case id = "EventId"
                case number = "EventNo"
            }
        }

        enum CodingKeys: String, CodingKey {
            case list = "list"
            case latestEventID = "LatestEventId"
            case latestEventNumber = "LatestEventNo"
        }
    }
}
// swiftlint:enable nesting
