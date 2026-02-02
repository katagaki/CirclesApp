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
            let eventID: Int
            let webCatalogID: Int
            let circleMsID: Int
            let name: String

            enum CodingKeys: String, CodingKey {
                case eventID = "EventId"
                case webCatalogID = "wcid"
                case circleMsID = "circlemsId"
                case name = "name"
            }
        }
    }
}
// swiftlint:enable nesting
