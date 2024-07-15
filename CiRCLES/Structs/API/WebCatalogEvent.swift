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
        let latestEventId: Int
        let latestEventNo: Int

        struct Event: Codable {
            let id: Int
            let number: Int

            enum CodingKeys: String, CodingKey {
                case id = "EventId"
                case number = "EventNo"
            }
        }

        enum CodingKeys: String, CodingKey {
            case list = "list"
            case latestEventId = "LatestEventId"
            case latestEventNo = "LatestEventNo"
        }
    }
}
// swiftlint:enable nesting
