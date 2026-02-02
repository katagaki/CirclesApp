//
//  WebCatalogEvent.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

// swiftlint:disable nesting
struct WebCatalogEvent: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let list: [Event]
        let latestEventID: Int
        let latestEventNumber: Int

        struct Event: Codable, Equatable {
            let id: Int
            let number: Int

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
