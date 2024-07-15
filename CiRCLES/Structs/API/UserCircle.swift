//
//  UserCircle.swift
//  CiRCLES
//
//  Created by シン・ジャスティン on 2024/07/15.
//

// swiftlint:disable nesting
struct UserCircle: Codable {
    let status: String
    let response: Response

    struct Response: Codable {
        let count: Int
        let circles: [Circle]

        struct Circle: Codable {
            let eventId: Int
            let webCatalogId: Int
            let circleMsId: Int
            let name: String

            enum CodingKeys: String, CodingKey {
                case eventId = "EventId"
                case webCatalogId = "wcid"
                case circleMsId = "circlemsId"
                case name = "name"
            }
        }
    }
}
// swiftlint:enable nesting
